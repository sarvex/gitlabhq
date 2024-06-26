# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::UserFinder, :clean_gitlab_redis_cache, feature_category: :importers do
  let(:project) do
    create(
      :project,
      import_type: 'github',
      import_url: 'https://api.github.com/user/repo'
    )
  end

  let(:client) { double(:client) }
  let(:finder) { described_class.new(project, client) }

  describe '#author_id_for' do
    context 'with default author_key' do
      it 'returns the user ID for the author of an object' do
        user = { id: 4, login: 'kittens' }
        note = { author: user }

        expect(finder).to receive(:user_id_for).with(user).and_return(42)

        expect(finder.author_id_for(note)).to eq([42, true])
      end

      it 'returns the ID of the project creator if no user ID could be found' do
        user = { id: 4, login: 'kittens' }
        note = { author: user }

        expect(finder).to receive(:user_id_for).with(user).and_return(nil)

        expect(finder.author_id_for(note)).to eq([project.creator_id, false])
      end

      it 'returns the ID of the ghost user when the object has no user' do
        note = { author: nil }

        expect(finder.author_id_for(note)).to eq([Users::Internal.ghost.id, true])
      end

      it 'returns the ID of the ghost user when the given object is nil' do
        expect(finder.author_id_for(nil)).to eq([Users::Internal.ghost.id, true])
      end
    end

    context 'with a non-default author_key' do
      let(:user) { { id: 4, login: 'kittens' } }

      shared_examples 'user ID finder' do |author_key|
        it 'returns the user ID for an object' do
          expect(finder).to receive(:user_id_for).with(user).and_return(42)

          expect(finder.author_id_for(issue_event, author_key: author_key)).to eq([42, true])
        end
      end

      context 'when the author_key parameter is :actor' do
        let(:issue_event) { { actor: user } }

        it_behaves_like 'user ID finder', :actor
      end

      context 'when the author_key parameter is :assignee' do
        let(:issue_event) { { assignee: user } }

        it_behaves_like 'user ID finder', :assignee
      end

      context 'when the author_key parameter is :requested_reviewer' do
        let(:issue_event) { { requested_reviewer: user } }

        it_behaves_like 'user ID finder', :requested_reviewer
      end

      context 'when the author_key parameter is :review_requester' do
        let(:issue_event) { { review_requester: user } }

        it_behaves_like 'user ID finder', :review_requester
      end
    end
  end

  describe '#assignee_id_for' do
    it 'returns the user ID for the assignee of an issuable' do
      user = { id: 4, login: 'kittens' }
      issue = { assignee: user }

      expect(finder).to receive(:user_id_for).with(user).and_return(42)
      expect(finder.assignee_id_for(issue)).to eq(42)
    end

    it 'returns nil if the issuable does not have an assignee' do
      issue = { assignee: nil }

      expect(finder).not_to receive(:user_id_for)
      expect(finder.assignee_id_for(issue)).to be_nil
    end
  end

  describe '#user_id_for' do
    it 'returns the user ID for the given user' do
      user = { id: 4, login: 'kittens' }

      expect(finder).to receive(:find).with(user[:id], user[:login]).and_return(42)
      expect(finder.user_id_for(user)).to eq(42)
    end

    it 'does not fail with empty input' do
      expect(finder.user_id_for(nil)).to eq(nil)
    end
  end

  describe '#find' do
    let(:user) { create(:user) }

    before do
      allow(finder).to receive(:email_for_github_username)
        .and_return(user.email)
    end

    context 'without a cache' do
      before do
        allow(finder).to receive(:find_from_cache).and_return([false, nil])
        expect(finder).to receive(:find_id_from_database).and_call_original
      end

      it 'finds a GitLab user for a GitHub user ID' do
        user.identities.create!(provider: :github, extern_uid: 42)

        expect(finder.find(42, user.username)).to eq(user.id)
      end

      it 'finds a GitLab user for a GitHub Email address' do
        expect(finder.find(42, user.username)).to eq(user.id)
      end
    end

    context 'with a cache' do
      it 'returns the cached user ID' do
        expect(finder).to receive(:find_from_cache).and_return([true, user.id])
        expect(finder).not_to receive(:find_id_from_database)

        expect(finder.find(42, user.username)).to eq(user.id)
      end

      it 'does not query the database if the cache key exists but is empty' do
        expect(finder).to receive(:find_from_cache).and_return([true, nil])
        expect(finder).not_to receive(:find_id_from_database)

        expect(finder.find(42, user.username)).to be_nil
      end
    end
  end

  describe '#find_from_cache' do
    it 'retrieves a GitLab user ID for a GitHub user ID' do
      expect(finder)
        .to receive(:cached_id_for_github_id)
        .with(42)
        .and_return([true, 4])

      expect(finder.find_from_cache(42)).to eq([true, 4])
    end

    it 'retrieves a GitLab user ID for a GitHub Email address' do
      email = 'kittens@example.com'

      expect(finder)
        .to receive(:cached_id_for_github_id)
        .with(42)
        .and_return([false, nil])

      expect(finder)
        .to receive(:cached_id_for_github_email)
        .with(email)
        .and_return([true, 4])

      expect(finder.find_from_cache(42, email)).to eq([true, 4])
    end

    it 'does not query the cache for an Email address when none is given' do
      expect(finder)
        .to receive(:cached_id_for_github_id)
        .with(42)
        .and_return([false, nil])

      expect(finder).not_to receive(:cached_id_for_github_id)

      expect(finder.find_from_cache(42)).to eq([false])
    end
  end

  describe '#find_id_from_database' do
    let(:user) { create(:user) }

    it 'returns the GitLab user ID for a GitHub user ID' do
      user.identities.create!(provider: :github, extern_uid: 42)

      expect(finder.find_id_from_database(42, user.email)).to eq(user.id)
    end

    it 'returns the GitLab user ID for a GitHub Email address' do
      expect(finder.find_id_from_database(42, user.email)).to eq(user.id)
    end
  end

  describe '#email_for_github_username' do
    let(:email) { 'kittens@example.com' }

    context 'when an Email address is cached' do
      it 'reads the Email address from the cache' do
        expect(Gitlab::Cache::Import::Caching)
          .to receive(:read)
          .and_return(email)

        expect(client).not_to receive(:user)
        expect(finder.email_for_github_username('kittens')).to eq(email)
      end
    end

    context 'when an Email address is not cached' do
      let(:user) { { email: email } }

      it 'retrieves and caches the Email address when an Email address is available' do
        expect(client).to receive(:user).with('kittens').and_return(user).once

        expect(Gitlab::Cache::Import::Caching)
          .to receive(:write)
          .with(an_instance_of(String), email, timeout: Gitlab::Cache::Import::Caching::TIMEOUT).and_call_original

        expect(finder.email_for_github_username('kittens')).to eq(email)
        expect(finder.email_for_github_username('kittens')).to eq(email)
      end

      it 'shortens the timeout for Email address in cache when an Email address is private/nil from GitHub' do
        user = { email: nil }
        expect(client).to receive(:user).with('kittens').and_return(user).once

        expect(Gitlab::Cache::Import::Caching)
          .to receive(:write)
          .with(an_instance_of(String), '', timeout: Gitlab::Cache::Import::Caching::SHORTER_TIMEOUT)
          .and_call_original

        expect(finder.email_for_github_username('kittens')).to be_nil
        expect(finder.email_for_github_username('kittens')).to be_nil
      end

      context 'when a username does not exist on GitHub' do
        it 'caches github username inexistence' do
          expect(client)
            .to receive(:user)
            .with('kittens')
            .and_raise(::Octokit::NotFound)
            .once

          expect(finder.email_for_github_username('kittens')).to be_nil
          expect(finder.email_for_github_username('kittens')).to be_nil
        end
      end
    end
  end

  describe '#cached_id_for_github_id' do
    let(:id) { 4 }

    it 'reads a user ID from the cache' do
      Gitlab::Cache::Import::Caching
        .write(described_class::ID_CACHE_KEY % id, 4)

      expect(finder.cached_id_for_github_id(id)).to eq([true, 4])
    end

    it 'reads a non existing cache key' do
      expect(finder.cached_id_for_github_id(id)).to eq([false, nil])
    end
  end

  describe '#cached_id_for_github_email' do
    let(:email) { 'kittens@example.com' }

    it 'reads a user ID from the cache' do
      Gitlab::Cache::Import::Caching
        .write(described_class::ID_FOR_EMAIL_CACHE_KEY % email, 4)

      expect(finder.cached_id_for_github_email(email)).to eq([true, 4])
    end

    it 'reads a non existing cache key' do
      expect(finder.cached_id_for_github_email(email)).to eq([false, nil])
    end
  end

  describe '#id_for_github_id' do
    let(:id) { 4 }

    it 'queries and caches the user ID for a given GitHub ID' do
      expect(finder).to receive(:query_id_for_github_id)
        .with(id)
        .and_return(42)

      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .with(described_class::ID_CACHE_KEY % id, 42)

      finder.id_for_github_id(id)
    end

    it 'caches a nil value if no ID could be found' do
      expect(finder).to receive(:query_id_for_github_id)
        .with(id)
        .and_return(nil)

      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .with(described_class::ID_CACHE_KEY % id, nil)

      finder.id_for_github_id(id)
    end

    context 'when importing from github enterprise' do
      let(:project) do
        create(
          :project,
          import_type: 'github',
          import_url: 'https://othergithub.net/user/repo'
        )
      end

      it 'does not look up the user by external id' do
        expect(finder).not_to receive(:query_id_for_github_id)

        expect(Gitlab::Cache::Import::Caching)
          .to receive(:write)
          .with(described_class::ID_CACHE_KEY % id, nil)

        finder.id_for_github_id(id)
      end
    end
  end

  describe '#id_for_github_email' do
    let(:email) { 'kittens@example.com' }

    it 'queries and caches the user ID for a given Email address' do
      expect(finder).to receive(:query_id_for_github_email)
        .with(email)
        .and_return(42)

      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .with(described_class::ID_FOR_EMAIL_CACHE_KEY % email, 42)

      finder.id_for_github_email(email)
    end

    it 'caches a nil value if no ID could be found' do
      expect(finder).to receive(:query_id_for_github_email)
        .with(email)
        .and_return(nil)

      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .with(described_class::ID_FOR_EMAIL_CACHE_KEY % email, nil)

      finder.id_for_github_email(email)
    end
  end

  describe '#query_id_for_github_id' do
    it 'returns the ID of the user for the given GitHub user ID' do
      user = create(:user)

      user.identities.create!(provider: :github, extern_uid: '42')

      expect(finder.query_id_for_github_id(42)).to eq(user.id)
    end

    it 'returns nil when no user ID could be found' do
      expect(finder.query_id_for_github_id(42)).to be_nil
    end
  end

  describe '#query_id_for_github_email' do
    it 'returns the ID of the user for the given Email address' do
      user = create(:user, email: 'kittens@example.com')

      expect(finder.query_id_for_github_email(user.email)).to eq(user.id)
    end

    it 'returns nil if no user ID could be found' do
      expect(finder.query_id_for_github_email('kittens@example.com')).to be_nil
    end
  end

  describe '#read_id_from_cache' do
    it 'reads an ID from the cache' do
      Gitlab::Cache::Import::Caching.write('foo', 10)

      expect(finder.read_id_from_cache('foo')).to eq([true, 10])
    end

    it 'reads a cache key with an empty value' do
      Gitlab::Cache::Import::Caching.write('foo', nil)

      expect(finder.read_id_from_cache('foo')).to eq([true, nil])
    end

    it 'reads a cache key that does not exist' do
      expect(finder.read_id_from_cache('foo')).to eq([false, nil])
    end
  end
end
