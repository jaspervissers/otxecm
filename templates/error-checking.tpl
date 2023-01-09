{{/*
Ensure password synchronization between OTCS, OTDS and OTAC. This ONLY validates
password values provided by helm directly. It does not compare values
provided by an existing Kubernetes secret.
*/}}
{{- if and (eq .Values.global.otcs.enabled true) (eq .Values.global.otds.enabled true) }}
	{{- if ne .Values.otcs.passwords.adminPassword .Values.otds.otdsws.otadminPassword }}
		{{- fail ".Values.otcs.passwords.adminPassword and .Values.otds.otdsws.otadminPassword do not match. These passwords must be the same." }}
	{{- end }}
	{{- if ne (int (.Values.otcs.config.otds.port)) (int (.Values.otds.otdsws.port)) }}
		{{- fail ".Values.otcs.config.otds.port and .Values.otds.otdsws.port do not match. The port must be the same." }}
	{{- end }}
{{- end }}
{{- if and (eq .Values.global.otac.enabled true) (eq .Values.global.otds.enabled true) }}
	{{- if ne .Values.otac.otds.password .Values.otds.otdsws.otadminPassword }}
		{{- fail ".Values.otac.otds.password and .Values.otds.otdsws.otadminPassword do not match. These passwords must be the same." }}
	{{- end }}
	{{- if ne (int (.Values.otac.otds.port)) (int (.Values.otds.otdsws.port)) }}
		{{- fail ".Values.otac.otds.port and .Values.otds.otdsws.port do not match. The port must be the same." }}
	{{- end }}
{{- end }}
{{- if and (eq .Values.global.otcs.enabled true) (eq .Values.global.otac.enabled true) }}
	{{- if ne .Values.otcs.passwords.adminPassword .Values.otac.otds.password }}
		{{- fail ".Values.otcs.passwords.adminPassword and .Values.otac.otds.password do not match. These passwords must be the same." }}
	{{- end }}
{{- end }}

{{/*
Validation of values provided by an existing Kubernetes secret
*/}}
{{- if .Values.global.existingSecret }}
	{{- $secret_object := lookup "v1" "Secret" .Release.Namespace .Values.global.existingSecret }}
	{{- if not $secret_object }}
		{{- fail "\n\nError: existing secret defined at .Values.global.existingSecret not found.\n" }}
	{{- else if not $secret_object.data }}
		{{- fail "\n\nError: keys from the existing secret set at .Values.global.existingSecret must be defined under the data section.\n" }}
	{{- end }}
	{{- $secrets := $secret_object.data }}
	{{- if not $secrets.DATA_ENCRYPTION_KEY }}
		{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set a DATA_ENCRYPTION_KEY.\n" }}
	{{- end }}
	{{- if eq .Values.global.otcs.enabled true }}
		{{- if not $secrets.ADMIN_USER_PASSWORD }}
			{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set an ADMIN_USER_PASSWORD since .Values.global.otcs.enabled is true.\n" }}
		{{- else if not $secrets.DB_ADMIN_PASSWORD }}
			{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set a DB_ADMIN_PASSWORD since .Values.global.otcs.enabled is true.\n" }}
		{{- else if not $secrets.DB_PASSWORD }}
			{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set a DB_PASSWORD since .Values.global.otcs.enabled is true.\n" }}
		{{- else if and (eq .Values.otcs.config.documentStorage.type "otacc") (not $secrets.AC_CORE_PASSWORD) }}
			{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set a AC_CORE_PASSWORD since OTCS is set to use OTACC.\n" }}
		{{- else if and (eq .Values.otcs.config.createBizadminUser true) (not $secrets.BIZ_ADMIN_PASSWORD) }}
			{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set a BIZ_ADMIN_PASSWORD since .Values.otcs.config.createBizadminUser is true.\n" }}
		{{- else if and (eq .Values.otcs.config.createAppMonitorUser true) (not $secrets.APPMONITOR_PASSWORD) }}
			{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set a APPMONITOR_PASSWORD since .Values.otcs.config.createAppMonitorUser is true.\n" }}
		{{- else if and (eq .Values.otcs.config.deployBusinessScenarios true) (not $secrets.SCENARIO_OWNER_PASSWORD) }}
			{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set a SCENARIO_OWNER_PASSWORD since .Values.otcs.config.deployBusinessScenarios is true.\n" }}
		{{- end }}
	{{- end }}
	{{- if eq .Values.global.otac.enabled true }}
		{{- if not $secrets.TARGET_DB_PASSWORD }}
			{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set a TARGET_DB_PASSWORD since .Values.global.otac.enabled is true.\n" }}
		{{- else if not $secrets.PG_PASSWORD }}
			{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set a PG_PASSWORD since .Values.global.otac.enabled is true.\n" }}
		{{- end }}
	{{- end }}
	{{- if (eq .Values.global.otac.enabled true) }}
		{{- if not $secrets.OTDS_PASS }}
			{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set an OTDS_PASS since .Values.global.otac.enabled is true.\n" }}
		{{- else if and (eq .Values.global.otcs.enabled true) (ne $secrets.ADMIN_USER_PASSWORD $secrets.OTDS_PASS) }}
			{{- fail "\n\nError: existing secret from .Values.global.existingSecret must have the same values for ADMIN_USER_PASSWORD and OTDS_PASS.\n" }}
		{{- end }}
	{{- end }}
	{{- if eq .Values.global.otacc.enabled true }}
		{{- if not $secrets.BA_PASSWORD }}
			{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set a BA_PASSWORD since .Values.global.otacc.enabled is true.\n" }}
		{{- else if not $secrets.CONNECTOR_PASSWORD }}
			{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set a CONNECTOR_PASSWORD since .Values.global.otacc.enabled is true.\n" }}
		{{- end }}
	{{- end }}
	{{- if eq .Values.global.otpd.enabled true }}
		{{- if ne .Values.global.otcs.enabled .Values.otpd.otcs.enabled }}
			{{- fail ".Values.global.otcs.enabled and .Values.otpd.otcs.enabled must be set to same value." }}
		{{- end}}
		{{- if eq .Values.otpd.otcs.enabled true }}
			{{- if not $secrets.OTCS_ADMIN_PASSWORD }}
				{{- fail "\n\nError: existing secret from .Values.global.existingSecret must set a OTCS_ADMIN_PASSWORD since .Values.otpd.otcs.enabled is true.\n" }}
			{{- else if ne $secrets.ADMIN_USER_PASSWORD $secrets.OTCS_ADMIN_PASSWORD }}
				{{- fail "\n\nError: existing secret from .Values.global.existingSecret must have the same values for ADMIN_USER_PASSWORD and OTCS_ADMIN_PASSWORD.\n" }}
			{{- end }}
		{{- end }}
	{{- end }}
{{- end }}

{{/*
Ensure oracle database has the correct values.
*/}}
{{- if and (ne .Values.otcs.config.database.type "oracle") (ne .Values.otcs.config.database.type "postgres")}}
	{{- fail ".Values.otcs.config.database.type must be either postgres or oracle" }}
{{- end}}
{{- if and (eq .Values.otcs.config.database.type "oracle") (eq .Values.global.otcs.enabled true)}}
	{{- if and (eq .Values.otcs.config.database.oracle.loadTnsnames.enabled true) (not .Values.otcs.config.database.oracle.tnsnamesConnectionAlias )}}
		{{- fail ".Values.otcs.config.database.oracle.tnsnamesConnectionAlias must be set to the connection alias to be used from the tnsnames file if .Values.otcs.config.database.oracle.loadTnsnames.enabled true" }}
	{{- end}}
	{{- if and (eq .Values.otcs.config.database.oracle.loadTnsnames.enabled false) (not .Values.otcs.config.database.oracle.serviceName )}}
		{{- fail ".Values.otcs.config.database.oracle.serviceName must be set to the pluggable database to use if .Values.otcs.config.database.oracle.loadTnsnames.enabled false" }}
	{{- end}}
	{{if (eq .Values.otcs.config.database.adminUsername "sys")}}
		{{- fail ".Values.otcs.config.database.adminUsername do not use sys user, instead use system."}}
	{{- end}}
{{- end}}

{{/*
Validation of values when otpd is enabled.
*/}}
{{- if eq .Values.global.otpd.enabled true }}
	{{- if ne .Values.global.otcs.enabled .Values.otpd.otcs.enabled }}
		{{- fail ".Values.global.otcs.enabled and .Values.otpd.otcs.enabled must be set to same value." }}
	{{- end}}
{{- end}}
