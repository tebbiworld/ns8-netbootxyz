<!--
  Copyright (C) 2026 tebbi
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title"><h2>{{ $t("settings.title") }}</h2></cv-column>
    </cv-row>
    <cv-row v-if="error.getConfiguration">
      <cv-column>
        <NsInlineNotification kind="error" :title="$t('action.get-configuration')" :description="error.getConfiguration" :showCloseButton="false" />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="configureModule">
            <!-- PXE boot -->
            <h4 class="section first">{{ $t("settings.pxe_section") }}</h4>
            <cv-dropdown
              :label="$t('settings.pxe_server_ip')"
              v-model="pxe_server_ip"
              :helper-text="$t('settings.pxe_server_ip_helper')"
              :invalid-message="$t(error.pxe_server_ip)"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="pxe_server_ip"
              class="field"
            >
              <cv-dropdown-item v-for="n in networks" :key="n.address" :value="n.address">
                {{ n.address }} ({{ n.interface }}, {{ n.network }}){{ n.dynamic ? " – " + $t("settings.dhcp_address") : "" }}
              </cv-dropdown-item>
            </cv-dropdown>
            <NsInlineNotification v-if="selectedNetwork && selectedNetwork.dynamic" kind="warning" :title="$t('settings.dynamic_warning_title')" :description="$t('settings.dynamic_warning_desc')" :showCloseButton="false" class="info-tile" />

            <cv-toggle value="proxy_dhcp" :label="$t('settings.proxy_dhcp')" v-model="proxy_dhcp" :disabled="loading.getConfiguration || loading.configureModule" class="toggle">
              <template slot="text-left">{{ $t("settings.disabled") }}</template>
              <template slot="text-right">{{ $t("settings.enabled") }}</template>
            </cv-toggle>
            <NsInlineNotification
              v-if="proxy_dhcp"
              kind="warning"
              :title="$t('settings.proxy_dhcp_on_title')"
              :description="$t('settings.proxy_dhcp_on_desc', { network: selectedNetwork ? selectedNetwork.network : '' })"
              :showCloseButton="false"
              class="info-tile"
            />
            <NsInlineNotification
              v-else
              kind="info"
              :title="$t('settings.router_options_title')"
              :description="$t('settings.router_options_desc', { ip: pxe_server_ip, uefi: uefiBootFile, bios: dhcp_options.option67_bios || 'netboot.xyz.kpxe' })"
              :showCloseButton="false"
              class="info-tile"
            />

            <cv-dropdown
              :label="$t('settings.uefi_boot_mode')"
              v-model="uefi_boot_mode"
              :helper-text="$t('settings.uefi_boot_mode_helper')"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="field"
            >
              <cv-dropdown-item value="standard">{{ $t("settings.uefi_standard") }}</cv-dropdown-item>
              <cv-dropdown-item value="secureboot">{{ $t("settings.uefi_secureboot") }}</cv-dropdown-item>
            </cv-dropdown>

            <!-- Web app -->
            <h4 class="section">{{ $t("settings.web_section") }}</h4>
            <p class="section-desc">{{ $t("settings.web_section_desc") }}</p>
            <cv-text-input
              :label="$t('settings.host')"
              v-model.trim="host"
              :placeholder="$t('settings.host_placeholder')"
              :helper-text="$t('settings.host_helper')"
              :disabled="loading.getConfiguration || loading.configureModule"
              :invalid-message="$t(error.host)"
              ref="host"
              class="field"
            ></cv-text-input>
            <template v-if="host">
              <cv-toggle value="lets_encrypt" :label="$t('settings.lets_encrypt')" v-model="lets_encrypt" :disabled="loading.getConfiguration || loading.configureModule" class="toggle">
                <template slot="text-left">{{ $t("settings.disabled") }}</template>
                <template slot="text-right">{{ $t("settings.enabled") }}</template>
              </cv-toggle>
              <cv-toggle value="http2https" :label="$t('settings.http2https')" v-model="http2https" :disabled="loading.getConfiguration || loading.configureModule" class="toggle">
                <template slot="text-left">{{ $t("settings.disabled") }}</template>
                <template slot="text-right">{{ $t("settings.enabled") }}</template>
              </cv-toggle>
              <cv-text-input
                :label="$t('settings.admin_user')"
                v-model.trim="admin_user"
                :disabled="loading.getConfiguration || loading.configureModule"
                :invalid-message="$t(error.admin_user)"
                ref="admin_user"
                class="field"
              ></cv-text-input>
              <cv-text-input
                type="password"
                :label="$t('settings.admin_password')"
                v-model="admin_password"
                :placeholder="admin_password_set ? $t('settings.secret_keep_placeholder') : ''"
                :helper-text="admin_password_set ? $t('settings.secret_is_set') : $t('settings.admin_password_helper')"
                :password-hide-label="$t('settings.hide')"
                :password-show-label="$t('settings.show')"
                :disabled="loading.getConfiguration || loading.configureModule"
                :invalid-message="$t(error.admin_password)"
                ref="admin_password"
                class="field"
              ></cv-text-input>
              <cv-text-area
                :label="$t('settings.ip_allowlist')"
                v-model="ip_allowlist"
                :placeholder="$t('settings.ip_allowlist_placeholder')"
                :helper-text="$t('settings.ip_allowlist_helper')"
                :invalid-message="$t(error.ip_allowlist)"
                :disabled="loading.getConfiguration || loading.configureModule"
                ref="ip_allowlist"
                class="field"
              ></cv-text-area>
              <NsInlineNotification v-if="url" kind="info" :title="$t('settings.web_url')" :description="$t('settings.web_url_desc', { url, user: admin_user })" :showCloseButton="false" class="info-tile" />
            </template>

            <cv-row v-if="error.configureModule">
              <cv-column>
                <NsInlineNotification kind="error" :title="$t('action.configure-module')" :description="error.configureModule" :showCloseButton="false" />
              </cv-column>
            </cv-row>
            <NsButton kind="primary" :icon="Save20" :loading="loading.configureModule" :disabled="loading.getConfiguration || loading.configureModule" class="save">{{ $t("settings.save") }}</NsButton>
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import { QueryParamService, UtilService, TaskService, IconService, PageTitleService } from "@nethserver/ns8-ui-lib";

const UEFI_FILES = { standard: "netboot.xyz.efi", secureboot: "secureboot-x86_64/shimx64.efi" };

export default {
  name: "Settings",
  mixins: [TaskService, IconService, UtilService, QueryParamService, PageTitleService],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: { page: "settings" },
      urlCheckInterval: null,
      networks: [],
      pxe_server_ip: "",
      proxy_dhcp: false,
      uefi_boot_mode: "standard",
      dhcp_options: {},
      host: "",
      lets_encrypt: false,
      http2https: true,
      admin_user: "admin",
      admin_password: "",
      admin_password_set: false,
      ip_allowlist: "",
      url: "",
      loading: { getConfiguration: false, configureModule: false },
      error: { getConfiguration: "", configureModule: "", host: "", admin_user: "", admin_password: "", ip_allowlist: "", pxe_server_ip: "" },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    selectedNetwork() {
      return this.networks.find((n) => n.address === this.pxe_server_ip) || null;
    },
    uefiBootFile() {
      return UEFI_FILES[this.uefi_boot_mode] || UEFI_FILES.standard;
    },
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  created() {
    this.getConfiguration();
  },
  methods: {
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";
      const eventId = this.getUuid();
      this.core.$root.$once(`${taskAction}-aborted-${eventId}`, this.getConfigurationAborted);
      this.core.$root.$once(`${taskAction}-completed-${eventId}`, this.getConfigurationCompleted);
      const res = await to(this.createModuleTaskForApp(this.instanceName, { action: taskAction, extra: { title: this.$t("action." + taskAction), isNotificationHidden: true, eventId } }));
      const err = res[0];
      if (err) {
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      this.loading.getConfiguration = false;
      const c = taskResult.output;
      this.networks = c.networks || [];
      this.pxe_server_ip = c.pxe_server_ip || "";
      this.proxy_dhcp = !!c.proxy_dhcp;
      this.uefi_boot_mode = c.uefi_boot_mode || "standard";
      this.dhcp_options = c.dhcp_options || {};
      this.host = c.host || "";
      this.lets_encrypt = !!c.lets_encrypt;
      this.http2https = c.http2https !== undefined ? !!c.http2https : true;
      this.admin_user = c.admin_user || "admin";
      this.admin_password_set = !!c.admin_password_set;
      this.ip_allowlist = (c.ip_allowlist || []).join("\n");
      this.url = c.url || "";
      // the password is never echoed back: start blank so a blank submit keeps it
      this.admin_password = "";
    },
    allowlistItems() {
      return this.ip_allowlist.split(/[\s,]+/).map((s) => s.trim()).filter((s) => s);
    },
    validateConfigureModule() {
      this.clearErrors(this);
      let ok = true;
      const fail = (field, msg) => {
        this.error[field] = msg;
        if (ok) this.focusElement(field);
        ok = false;
      };
      if (!this.pxe_server_ip) fail("pxe_server_ip", "common.required");
      if (this.host) {
        if (!/^[A-Za-z0-9._-]{1,64}$/.test(this.admin_user)) fail("admin_user", "settings.admin_user_invalid");
        if (!this.admin_password && !this.admin_password_set) fail("admin_password", "settings.admin_password_required");
        if (this.admin_password && this.admin_password.length < 8) fail("admin_password", "settings.admin_password_too_short");
        const cidr = /^\d{1,3}(\.\d{1,3}){3}(\/\d{1,2})?$|^[0-9a-fA-F:]+(\/\d{1,3})?$/;
        if (this.allowlistItems().some((c) => !cidr.test(c))) fail("ip_allowlist", "settings.invalid_cidr");
      }
      return ok;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      let focusSet = false;
      for (const e of validationErrors) {
        if (e.field !== "(root)") {
          this.error[e.field] = this.$t("settings." + e.error);
          if (!focusSet) {
            this.focusElement(e.field);
            focusSet = true;
          }
        }
      }
    },
    async configureModule() {
      if (!this.validateConfigureModule()) return;
      this.loading.configureModule = true;
      const taskAction = "configure-module";
      const eventId = this.getUuid();
      this.core.$root.$once(`${taskAction}-aborted-${eventId}`, this.configureModuleAborted);
      this.core.$root.$once(`${taskAction}-validation-failed-${eventId}`, this.configureModuleValidationFailed);
      this.core.$root.$once(`${taskAction}-completed-${eventId}`, this.configureModuleCompleted);
      const data = {
        host: this.host,
        lets_encrypt: this.lets_encrypt,
        http2https: this.http2https,
        admin_user: this.admin_user || "admin",
        admin_password: this.admin_password,
        ip_allowlist: this.host ? this.allowlistItems() : [],
        pxe_server_ip: this.pxe_server_ip,
        proxy_dhcp: this.proxy_dhcp,
        uefi_boot_mode: this.uefi_boot_mode,
      };
      const res = await to(this.createModuleTaskForApp(this.instanceName, {
        action: taskAction,
        data,
        extra: { title: this.$t("settings.configure_instance", { instance: this.instanceName }), description: this.$t("common.processing"), eventId },
      }));
      const err = res[0];
      if (err) {
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
      }
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;
      this.getConfiguration();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
.field { margin-top: $spacing-06; }
.toggle { margin-top: $spacing-06; }
.info-tile { margin-top: $spacing-05; }
.section { margin-top: $spacing-08; margin-bottom: $spacing-03; }
.section.first { margin-top: 0; }
.section-desc { margin-bottom: $spacing-03; }
.save { margin-top: $spacing-07; }
</style>
