import Vue from 'vue';
import NewProjectCreationApp from './components/app.vue';

export default function initNewProjectCreation(el, props) {
  return new Vue({
    el,
    components: {
      NewProjectCreationApp,
    },
    render(h) {
      return h(NewProjectCreationApp, { props });
    },
  });
}
