---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab 14 changes **(FREE SELF)**

This page contains upgrade information for minor and patch versions of GitLab 14.
Ensure you review these instructions for all versions between your current version and your target version.

For more information about upgrading GitLab Helm Chart, see [the release notes for 5.0](https://docs.gitlab.com/charts/releases/5_0.html).

## 14.10.0

- Before upgrading to GitLab 14.10, you must already have the latest 14.9.Z installed on your instance.
  The upgrade to GitLab 14.10 executes a [concurrent index drop](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/84308) of unneeded
  entries from the `ci_job_artifacts` database table. This could potentially run for multiple minutes, especially if the table has a lot of
  traffic and the migration is unable to acquire a lock. It is advised to let this process finish as restarting may result in data loss.

- If you run external PostgreSQL, particularly AWS RDS,
  [check you have a PostgreSQL bug fix](../index.md#postgresql-segmentation-fault-issue)
  to avoid the database crashing.

- Upgrading to patch level 14.10.3 or later might encounter a one-hour timeout due to a long running database data change,
  if it was not completed while running GitLab 14.9.

  ```plaintext
  FATAL: Mixlib::ShellOut::CommandTimeout: rails_migration[gitlab-rails]
  (gitlab::database_migrations line 51) had an error:
  [..]
  Mixlib::ShellOut::CommandTimeout: Command timed out after 3600s:
  ```

  A workaround exists to [complete the data change and the upgrade manually](../package/index.md#mixlibshelloutcommandtimeout-rails_migrationgitlab-rails--command-timed-out-after-3600s).

## 14.9.0

- Database changes made by the upgrade to GitLab 14.9 can take hours or days to complete on larger GitLab instances.
  These [batched background migrations](../background_migrations.md#batched-background-migrations) update whole database tables to ensure corresponding
  records in `namespaces` table for each record in `projects` table.

  After you upgrade to 14.9.0 or a later 14.9 patch version,
  [batched background migrations must finish](../background_migrations.md#batched-background-migrations)
  before you upgrade to a later version.

  If the migrations are not finished and you try to upgrade to a later version,
  you see errors like:

  ```plaintext
  Expected batched background migration for the given configuration to be marked as 'finished', but it is 'active':
  ```

  Or

  ```plaintext
  Error executing action `run` on resource 'bash[migrate gitlab-rails database]'
  ================================================================================

  Mixlib::ShellOut::ShellCommandFailed
  ------------------------------------
  Command execution failed. STDOUT/STDERR suppressed for sensitive resource
  ```

- GitLab 14.9.0 includes a
  [background migration `ResetDuplicateCiRunnersTokenValuesOnProjects`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/79140)
  that may remain stuck permanently in a **pending** state.

  To clean up this stuck job, run the following in the [GitLab Rails Console](../../administration/operations/rails_console.md):

  ```ruby
  Gitlab::Database::BackgroundMigrationJob.pending.where(class_name: "ResetDuplicateCiRunnersTokenValuesOnProjects").find_each do |job|
    puts Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded("ResetDuplicateCiRunnersTokenValuesOnProjects", job.arguments)
  end
  ```

- If you run external PostgreSQL, particularly AWS RDS,
  [check you have a PostgreSQL bug fix](../index.md#postgresql-segmentation-fault-issue)
  to avoid the database crashing.

## 14.8.0

- If upgrading from a version earlier than 14.6.5, 14.7.4, or 14.8.2, review the [Critical Security Release: 14.8.2, 14.7.4, and 14.6.5](https://about.gitlab.com/releases/2022/02/25/critical-security-release-gitlab-14-8-2-released/) blog post.
  Updating to 14.8.2 or later resets runner registration tokens for your groups and projects.
- The agent server for Kubernetes [is enabled by default](https://about.gitlab.com/releases/2022/02/22/gitlab-14-8-released/#the-agent-server-for-kubernetes-is-enabled-by-default)
  on Omnibus installations. If you run GitLab at scale,
  such as [the reference architectures](../../administration/reference_architectures/index.md),
  you must disable the agent on the following server types, **if the agent is not required**.

  - Praefect
  - Gitaly
  - Sidekiq
  - Redis (if configured using `redis['enable'] = true` and not via `roles`)
  - Container registry
  - Any other server types based on `roles(['application_role'])`, such as the GitLab Rails nodes

  [The reference architectures](../../administration/reference_architectures/index.md) have been updated
  with this configuration change and a specific role for standalone Redis servers.

  Steps to disable the agent:

  1. Add `gitlab_kas['enable'] = false` to `gitlab.rb`.
  1. If the server is already upgraded to 14.8, run `gitlab-ctl reconfigure`.
- GitLab 14.8.0 includes a
[background migration `PopulateTopicsNonPrivateProjectsCount`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/79140)
that may remain stuck permanently in a **pending** state.

  To clean up this stuck job, run the following in the [GitLab Rails Console](../../administration/operations/rails_console.md):

  ```ruby
  Gitlab::Database::BackgroundMigrationJob.pending.where(class_name: "PopulateTopicsNonPrivateProjectsCount").find_each do |job|
    puts Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded("PopulateTopicsNonPrivateProjectsCount", job.arguments)
  end
  ```

- If upgrading from a version earlier than 14.3.0, to avoid
  [an issue with job retries](https://gitlab.com/gitlab-org/gitlab/-/issues/357822), first upgrade
  to GitLab 14.7.x and make sure all batched migrations have finished.
- If upgrading from version 14.3.0 or later, you might notice a failed
  [batched migration](../background_migrations.md#batched-background-migrations) named
  `BackfillNamespaceIdForNamespaceRoute`. You can [ignore](https://gitlab.com/gitlab-org/gitlab/-/issues/357822)
  this. Retry it after you upgrade to version 14.9.x.
- If you run external PostgreSQL, particularly AWS RDS,
  [check you have a PostgreSQL bug fix](../index.md#postgresql-segmentation-fault-issue)
  to avoid the database crashing.

## 14.7.0

- See [LFS objects import and mirror issue in GitLab 14.6.0 to 14.7.2](../index.md#lfs-objects-import-and-mirror-issue-in-gitlab-1460-to-1472).
- If upgrading from a version earlier than 14.6.5, 14.7.4, or 14.8.2, review the [Critical Security Release: 14.8.2, 14.7.4, and 14.6.5](https://about.gitlab.com/releases/2022/02/25/critical-security-release-gitlab-14-8-2-released/) blog post.
  Updating to 14.7.4 or later resets runner registration tokens for your groups and projects.
- GitLab 14.7 introduced a change where Gitaly expects persistent files in the `/tmp` directory.
  When using the `noatime` mount option on `/tmp` in a node running Gitaly, most Linux distributions
  run into [an issue with Git server hooks getting deleted](https://gitlab.com/gitlab-org/gitaly/-/issues/4113).
  These conditions are present in the default Amazon Linux configuration.

  If your Linux distribution manages files in `/tmp` with the `tmpfiles.d` service, you
  can override the behavior of `tmpfiles.d` for the Gitaly files and avoid this issue:

  ```shell
  sudo printf "x /tmp/gitaly-%s-*\n" hooks git-exec-path >/etc/tmpfiles.d/gitaly-workaround.conf
  ```

  This issue is fixed in GitLab 14.10 and later when using the [Gitaly runtime directory](https://docs.gitlab.com/omnibus/update/gitlab_14_changes.html#gitaly-runtime-directory)
  to specify a location to store persistent files.

## 14.6.0

- See [LFS objects import and mirror issue in GitLab 14.6.0 to 14.7.2](../index.md#lfs-objects-import-and-mirror-issue-in-gitlab-1460-to-1472).
- If upgrading from a version earlier than 14.6.5, 14.7.4, or 14.8.2, review the [Critical Security Release: 14.8.2, 14.7.4, and 14.6.5](https://about.gitlab.com/releases/2022/02/25/critical-security-release-gitlab-14-8-2-released/) blog post.
  Updating to 14.6.5 or later resets runner registration tokens for your groups and projects.

## 14.5.0

- When `make` is run, Gitaly builds are now created in `_build/bin` and no longer in the root directory of the source directory. If you
are using a self-compiled installation, update paths to these binaries in your [systemd unit files](../upgrading_from_source.md#configure-systemd-units)
or [init scripts](../upgrading_from_source.md#configure-sysv-init-script) by [following the documentation](../upgrading_from_source.md).

- Connections between Workhorse and Gitaly use the Gitaly `backchannel` protocol by default. If you deployed a gRPC proxy between Workhorse and Gitaly,
  Workhorse can no longer connect. As a workaround, [disable the temporary `workhorse_use_sidechannel`](../../administration/feature_flags.md#enable-or-disable-the-feature)
  feature flag. If you need a proxy between Workhorse and Gitaly, use a TCP proxy. If you have feedback about this change, go to [this issue](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1301).

- In 14.1 we introduced a background migration that changes how we store merge request diff commits,
  to significantly reduce the amount of storage needed.
  In 14.5 we introduce a set of migrations that wrap up this process by making sure
  that all remaining jobs over the `merge_request_diff_commits` table are completed.
  These jobs have already been processed in most cases so that no extra time is necessary during an upgrade to 14.5.
  However, if there are remaining jobs or you haven't already upgraded to 14.1,
  the deployment may take multiple hours to complete.

  All merge request diff commits automatically incorporate these changes, and there are no
  additional requirements to perform the upgrade.
  Existing data in the `merge_request_diff_commits` table remains unpacked until you run `VACUUM FULL merge_request_diff_commits`.
  However, the `VACUUM FULL` operation locks and rewrites the entire `merge_request_diff_commits` table,
  so the operation takes some time to complete and it blocks access to this table until the end of the process.
  We advise you to only run this command while GitLab is not actively used or it is taken offline for the duration of the process.
  The time it takes to complete depends on the size of the table, which can be obtained by using `select pg_size_pretty(pg_total_relation_size('merge_request_diff_commits'));`.

  For more information, refer to [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/331823).

- GitLab 14.5.0 includes a
  [background migration `UpdateVulnerabilityOccurrencesLocation`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72788)
  that may remain stuck permanently in a **pending** state when the instance lacks records that match the migration's target.

  To clean up this stuck job, run the following in the [GitLab Rails Console](../../administration/operations/rails_console.md):

  ```ruby
  Gitlab::Database::BackgroundMigrationJob.pending.where(class_name: "UpdateVulnerabilityOccurrencesLocation").find_each do |job|
    puts Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded("UpdateVulnerabilityOccurrencesLocation", job.arguments)
  end
  ```

- Upgrading to 14.5 (or later) [might encounter a one hour timeout](https://gitlab.com/gitlab-org/gitlab/-/issues/354211)
  owing to a long running database data change.

  ```plaintext
  FATAL: Mixlib::ShellOut::CommandTimeout: rails_migration[gitlab-rails]
  (gitlab::database_migrations line 51) had an error:
  [..]
  Mixlib::ShellOut::CommandTimeout: Command timed out after 3600s:
  ```

  [There is a workaround to complete the data change and the upgrade manually](../package/index.md#mixlibshelloutcommandtimeout-rails_migrationgitlab-rails--command-timed-out-after-3600s)

- As part of [enabling real-time issue assignees](https://gitlab.com/gitlab-org/gitlab/-/issues/330117), Action Cable is now enabled by default.
  For **self-compiled (source) installations**, `config/cable.yml` is required to be present.

  Configure this by running:

  ```shell
  cd /home/git/gitlab
  sudo -u git -H cp config/cable.yml.example config/cable.yml

  # Change the Redis socket path if you are not using the default Debian / Ubuntu configuration
  sudo -u git -H editor config/cable.yml
  ```

## 14.4.4

- For [zero-downtime upgrades](../zero_downtime.md) on a GitLab cluster with separate Web and API nodes, you must enable the `paginated_tree_graphql_query` [feature flag](../../administration/feature_flags.md#enable-or-disable-the-feature) _before_ upgrading GitLab Web nodes to 14.4.
  This is because we [enabled `paginated_tree_graphql_query` by default in 14.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/70913/diffs), so if GitLab UI is on 14.4 and its API is on 14.3, the frontend has this feature enabled but the backend has it disabled. This results in the following error:

  ```shell
  bundle.esm.js:63 Uncaught (in promise) Error: GraphQL error: Field 'paginatedTree' doesn't exist on type 'Repository'
  ```

## 14.4.0

- Git 2.33.x and later is required. We recommend you use the
  [Git version provided by Gitaly](../../install/installation.md#git).
- See [Maintenance mode issue in GitLab 13.9 to 14.4](../index.md#maintenance-mode-issue-in-gitlab-139-to-144).
- After enabling database load balancing by default in 14.4.0, we found an issue where
  [cron jobs would not work if the connection to PostgreSQL was severed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/73716),
  as Sidekiq would continue using a bad connection. Geo and other features that rely on
  cron jobs running regularly do not work until Sidekiq is restarted. We recommend
  upgrading to GitLab 14.4.3 and later if this issue affects you.
- After enabling database load balancing by default in 14.4.0, we found an issue where
  [Database load balancing does not work with an AWS Aurora cluster](https://gitlab.com/gitlab-org/gitlab/-/issues/220617).
  We recommend moving your databases from Aurora to RDS for PostgreSQL before
  upgrading. Refer to [Moving GitLab databases to a different PostgreSQL instance](../../administration/postgresql/moving.md).
- GitLab 14.4.0 includes a
[background migration `PopulateTopicsTotalProjectsCountCache`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71033)
that may remain stuck permanently in a **pending** state when the instance lacks records that match the migration's target.

  To clean up this stuck job, run the following in the [GitLab Rails Console](../../administration/operations/rails_console.md):

  ```ruby
  Gitlab::Database::BackgroundMigrationJob.pending.where(class_name: "PopulateTopicsTotalProjectsCountCache").find_each do |job|
    puts Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded("PopulateTopicsTotalProjectsCountCache", job.arguments)
  end
  ```

## 14.3.0

- [Instances running 14.0.0 - 14.0.4 should not upgrade directly to GitLab 14.2 or later](#upgrading-to-later-14y-releases).
- Ensure [batched background migrations finish](../background_migrations.md#batched-background-migrations) before upgrading
  to 14.3.Z from earlier GitLab 14 releases.
- Ruby 2.7.4 is required. Refer to [the Ruby installation instructions](../../install/installation.md#2-ruby)
for how to proceed.
- GitLab 14.3.0 contains post-deployment migrations to [address Primary Key overflow risk for tables with an integer PK](https://gitlab.com/groups/gitlab-org/-/epics/4785) for the tables listed below:

  - [`ci_builds.id`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/70245)
  - [`ci_builds.stage_id`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66688)
  - [`ci_builds_metadata`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/65692)
  - [`taggings`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66625)
  - [`events`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64779)

  If the migrations are executed as part of a no-downtime deployment, there's a risk of failure due to lock conflicts with the application logic, resulting in lock timeout or deadlocks. In each case, these migrations are safe to re-run until successful:

  ```shell
  # For Omnibus GitLab
  sudo gitlab-rake db:migrate

  # For source installations
  sudo -u git -H bundle exec rake db:migrate RAILS_ENV=production
  ```

- After upgrading to 14.3, ensure that all the `MigrateMergeRequestDiffCommitUsers` background
  migration jobs have completed before continuing with upgrading to GitLab 14.5 or later.
  This is especially important if your GitLab instance has a large
  `merge_request_diff_commits` table. Any pending
  `MigrateMergeRequestDiffCommitUsers` background migration jobs are
  foregrounded in GitLab 14.5, and may take a long time to complete.
  You can check the count of pending jobs for
  `MigrateMergeRequestDiffCommitUsers` by using the PostgreSQL console (or `sudo
  gitlab-psql`):

  ```sql
  select status, count(*) from background_migration_jobs
  where class_name = 'MigrateMergeRequestDiffCommitUsers' group by status;
  ```

  As jobs are completed, the database records change from `0` (pending) to `1`. If the number of
  pending jobs doesn't decrease after a while, it's possible that the
  `MigrateMergeRequestDiffCommitUsers` background migration jobs have failed. You
  can check for errors in the Sidekiq logs:

  ```shell
  sudo grep MigrateMergeRequestDiffCommitUsers /var/log/gitlab/sidekiq/current | grep -i error
  ```

  If needed, you can attempt to run the `MigrateMergeRequestDiffCommitUsers` background
  migration jobs manually in the [GitLab Rails Console](../../administration/operations/rails_console.md).
  This can be done using Sidekiq asynchronously, or by using a Rails process directly:

  - Using Sidekiq to schedule jobs asynchronously:

    ```ruby
    # For the first run, only attempt to execute 1 migration. If successful, increase
    # the limit for subsequent runs
    limit = 1

    jobs = Gitlab::Database::BackgroundMigrationJob.for_migration_class('MigrateMergeRequestDiffCommitUsers').pending.to_a

    pp "#{jobs.length} jobs remaining"

    jobs.first(limit).each do |job|
      BackgroundMigrationWorker.perform_in(5.minutes, 'MigrateMergeRequestDiffCommitUsers', job.arguments)
    end
    ```

    NOTE:
    The queued jobs can be monitored using the Sidekiq admin panel, which can be accessed at the `/admin/sidekiq` endpoint URI.

  - Using a Rails process to run jobs synchronously:

    ```ruby
    def process(concurrency: 1)
      queue = Queue.new

      Gitlab::Database::BackgroundMigrationJob
        .where(class_name: 'MigrateMergeRequestDiffCommitUsers', status: 0)
        .each { |job| queue << job }

      concurrency
        .times
        .map do
          Thread.new do
            Thread.abort_on_exception = true

            loop do
              job = queue.pop(true)
              time = Benchmark.measure do
                Gitlab::BackgroundMigration::MigrateMergeRequestDiffCommitUsers
                  .new
                  .perform(*job.arguments)
              end

              puts "#{job.id} finished in #{time.real.round(2)} seconds"
            rescue ThreadError
              break
            end
          end
        end
        .each(&:join)
    end

    ActiveRecord::Base.logger.level = Logger::ERROR
    process
    ```

    NOTE:
    When using Rails to execute these background migrations synchronously, make sure that the machine running the process has sufficient resources to handle the task. If the process gets terminated, it's likely due to insufficient memory available. If your SSH session times out after a while, it might be necessary to run the previous code by using a terminal multiplexer like `screen` or `tmux`.

- See [Maintenance mode issue in GitLab 13.9 to 14.4](../index.md#maintenance-mode-issue-in-gitlab-139-to-144).

- You may see the following error when setting up two factor authentication (2FA) for accounts
  that authenticate using an LDAP password:

  ```plaintext
  You must provide a valid current password
  ```

  - The error occurs because verification is incorrectly performed against accounts'
    randomly generated internal GitLab passwords, not the LDAP passwords.
  - This is [fixed in GitLab 14.5.0 and backported to 14.4.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/73538).
  - Workarounds:
    - Instead of upgrading to GitLab 14.3.x to comply with the supported upgrade path:
      1. Upgrade to 14.4.5.
      1. Make sure the [`MigrateMergeRequestDiffCommitUsers` background migration](#1430) has finished.
      1. Upgrade to GitLab 14.5 or later.
    - Reset the random password for affected accounts, using [the Rake task](../../security/reset_user_password.md#use-a-rake-task):

      ```plaintext
      sudo gitlab-rake "gitlab:password:reset[user_handle]"
      ```

- If you encounter the error, `I18n::InvalidLocale: :en is not a valid locale`, when starting the application, follow the [patching](https://about.gitlab.com/handbook/support/workflows/patching_an_instance.html) process. Use [122978](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122978) as the `mr_iid`.

## 14.2.0

- [Instances running 14.0.0 - 14.0.4 should not upgrade directly to GitLab 14.2 or later](#upgrading-to-later-14y-releases).
- Ensure [batched background migrations finish](../background_migrations.md#batched-background-migrations) before upgrading
  to 14.2.Z from earlier GitLab 14 releases.
- GitLab 14.2.0 contains background migrations to [address Primary Key overflow risk for tables with an integer PK](https://gitlab.com/groups/gitlab-org/-/epics/4785) for the tables listed below:
  - [`ci_build_needs`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/65216)
  - [`ci_build_trace_chunks`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66123)
  - [`ci_builds_runner_session`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66433)
  - [`deployments`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67341)
  - [`geo_job_artifact_deleted_events`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66763)
  - [`push_event_payloads`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67299)
  - `ci_job_artifacts`:
    - [Finalize `job_id` conversion to `bigint` for `ci_job_artifacts`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67774)
    - [Finalize `ci_job_artifacts` conversion to `bigint`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/65601)

  If the migrations are executed as part of a no-downtime deployment, there's a risk of failure due to lock conflicts with the application logic, resulting in lock timeout or deadlocks. In each case, these migrations are safe to re-run until successful:

  ```shell
  # For Omnibus GitLab
  sudo gitlab-rake db:migrate

  # For source installations
  sudo -u git -H bundle exec rake db:migrate RAILS_ENV=production
  ```

- See [Maintenance mode issue in GitLab 13.9 to 14.4](../index.md#maintenance-mode-issue-in-gitlab-139-to-144).
- GitLab 14.2.0 includes a
  [background migration `BackfillDraftStatusOnMergeRequests`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67687)
  that may remain stuck permanently in a **pending** state when the instance lacks records that match the migration's target.

  To clean up this stuck job, run the following in the [GitLab Rails Console](../../administration/operations/rails_console.md):

  ```ruby
  Gitlab::Database::BackgroundMigrationJob.pending.where(class_name: "BackfillDraftStatusOnMergeRequests").find_each do |job|
    puts Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded("BackfillDraftStatusOnMergeRequests", job.arguments)
  end
  ```

- If you encounter the error, `I18n::InvalidLocale: :en is not a valid locale`, when starting the application, follow the [patching](https://about.gitlab.com/handbook/support/workflows/patching_an_instance.html) process. Use [123476](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123476) as the `mr_iid`.

## 14.1.0

- [Instances running 14.0.0 - 14.0.4 should not upgrade directly to GitLab 14.2 or later](#upgrading-to-later-14y-releases)
  but can upgrade to 14.1.Z.

  It is not required for instances already running 14.0.5 (or later) to stop at 14.1.Z.
  14.1 is included on the upgrade path for the broadest compatibility
  with self-managed installations, and ensure 14.0.0-14.0.4 installations do not
  encounter issues with [batched background migrations](../background_migrations.md#batched-background-migrations).

- Upgrading to GitLab [14.5](#1450) (or later) may take a lot longer if you do not upgrade to at least 14.1
  first. The 14.1 merge request diff commits database migration can take hours to run, but runs in the
  background while GitLab is in use. GitLab instances upgraded directly from 14.0 to 14.5 or later must
  run the migration in the foreground and therefore take a lot longer to complete.

- See [Maintenance mode issue in GitLab 13.9 to 14.4](../index.md#maintenance-mode-issue-in-gitlab-139-to-144).

- If you encounter the error, `I18n::InvalidLocale: :en is not a valid locale`, when starting the application, follow the [patching](https://about.gitlab.com/handbook/support/workflows/patching_an_instance.html) process. Use [123475](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123475) as the `mr_iid`.

## 14.0.0

Prerequisites:

- The [GitLab 14.0 release post contains several important notes](https://about.gitlab.com/releases/2021/06/22/gitlab-14-0-released/#upgrade)
  about pre-requisites including [using Patroni instead of repmgr](../../administration/postgresql/replication_and_failover.md#switching-from-repmgr-to-patroni),
  migrating [to hashed storage](../../administration/raketasks/storage.md#migrate-to-hashed-storage),
  and [to Puma](../../administration/operations/puma.md).
- The support of PostgreSQL 11 [has been dropped](../../install/requirements.md#database). Make sure to [update your database](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server) to version 12 before updating to GitLab 14.0.

Long running batched background database migrations:

- Database changes made by the upgrade to GitLab 14.0 can take hours or days to complete on larger GitLab instances.
  These [batched background migrations](../background_migrations.md#batched-background-migrations) update whole database tables to mitigate primary key overflow and must be finished before upgrading to GitLab 14.2 or later.
- Due to an issue where `BatchedBackgroundMigrationWorkers` were
  [not working](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2785#note_614738345)
  for self-managed instances, a [fix was created](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/65106)
  that requires an update to at least 14.0.5. The fix was also released in [14.1.0](#1410).

  After you update to 14.0.5 or a later 14.0 patch version,
  [batched background migrations must finish](../background_migrations.md#batched-background-migrations)
  before you upgrade to a later version.

  If the migrations are not finished and you try to upgrade to a later version,
  you see an error like:

  ```plaintext
  Expected batched background migration for the given configuration to be marked as 'finished', but it is 'active':
  ```

  See how to [resolve this error](../background_migrations.md#database-migrations-failing-because-of-batched-background-migration-not-finished).

Other issues:

- In GitLab 13.3 some [pipeline processing methods were deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/218536)
  and this code was completely removed in GitLab 14.0. If you plan to upgrade from
  **GitLab 13.2 or older** directly to 14.0, this is [unsupported](../index.md#upgrading-to-a-new-major-version).
  You should instead follow a [supported upgrade path](../index.md#upgrade-paths).
- See [Maintenance mode issue in GitLab 13.9 to 14.4](../index.md#maintenance-mode-issue-in-gitlab-139-to-144).
- **In GitLab 13.12.2 and later**, users with expired passwords can no longer authenticate with API and Git using tokens because of
  the [Insufficient Expired Password Validation](https://about.gitlab.com/releases/2021/06/01/security-release-gitlab-13-12-2-released/#insufficient-expired-password-validation)
  security fix. If your users get authentication issues following the upgrade, check that their password is not expired:

  1. [Connect to the PostgreSQL database](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-postgresql-database) and execute the
     following query:

     ```sql
     select id,username,password_expires_at from users where password_expires_at < now();
     ```

  1. If the user is in the returned list, reset the `password_expires_at` for that user:

     ```sql
     update users set password_expires_at = null where username='<USERNAME>';
     ```

### Upgrading to later 14.Y releases

- Instances running 14.0.0 - 14.0.4 should not upgrade directly to GitLab 14.2 or later,
  because of [batched background migrations](../background_migrations.md#batched-background-migrations).
  1. Upgrade first to either:
     - 14.0.5 or a later 14.0.Z patch release.
     - 14.1.0 or a later 14.1.Z patch release.
  1. [Batched background migrations must finish](../background_migrations.md#batched-background-migrations)
     before you upgrade to a later version [and may take longer than usual](#1400).
