import Component from "@glimmer/component";
import icon from "discourse-common/helpers/d-icon";

export default class UserResponseTime extends Component {
  get responseTime() {
    var t = this.args.user.response_time_seconds || 86400;
    return I18n.t("user_response_times.user_card", { time: moment.duration(t*1000).humanize() });
  }

  get mustShow() {
    return this.args.user.response_time_seconds > 0
  }

  <template>
    {{#if this.mustShow}}
      {{icon 'far-clock'}} {{ this.responseTime }}
    {{/if}}
  </template>
}
