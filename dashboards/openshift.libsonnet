local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local graphPanel = grafana.graphPanel;
local prometheus = grafana.prometheus;
local row = grafana.row;
local template = grafana.template;

{
  grafanaDashboards+:: {
    'openshift.json':
      local apiserverRow = row.new()
                        .addPanel(
        graphPanel.new(
          'API Server',
          datasource='$datasource',
          min=0,
          format='bytes',
          legend_rightSide=true,
          legend_alignAsTable=true,
          legend_current=true,
          legend_avg=true,
        )
        .addTarget(prometheus.target(
          'sort_desc(sum without (instance,type,client,contentType) (irate(apiserver_request_count{verb!~"GET|LIST|WATCH"}[2m]))) > 0' % $._config,
        ))
      );

      dashboard.new(
        'Openshift metrics',
        time_from='now-1h',
        uid=($._config.grafanaDashboardIDs['openshift.json']),
      ).addTemplate(
        {
          current: {
            text: 'Prometheus',
            value: 'Prometheus',
          },
          hide: 0,
          label: null,
          name: 'datasource',
          options: [],
          query: 'prometheus',
          refresh: 1,
          regex: '',
          type: 'datasource',
        },
      )
      .addTemplate(
        template.new(
          'namespace',
          '$datasource',
          'label_values(kube_pod_info, namespace)',
          label='Namespace',
          refresh='time',
        )
      )
      .addTemplate(
        template.new(
          'pod',
          '$datasource',
          'label_values(kube_pod_info{namespace=~"$namespace"}, pod)',
          label='Pod',
          refresh='time',
        )
      )
      .addTemplate(
        template.new(
          'container',
          '$datasource',
          'label_values(kube_pod_container_info{namespace="$namespace", pod="$pod"}, container)',
          label='Container',
          refresh='time',
          includeAll=true,
        )
      )
      .addRow(apiserverRow),
  },
}