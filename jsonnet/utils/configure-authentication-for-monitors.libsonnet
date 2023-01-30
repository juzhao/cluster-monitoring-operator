{
  configureAuthenticationForMonitors(o): {
    local configureAuthentication(o) = o {
      [if (o.kind == 'ServiceMonitor' && o.metadata.name != 'etcd') || o.kind == 'PodMonitor' then 'spec']+: {
        [if o.kind == 'ServiceMonitor' then 'endpoints' else 'podMetricsEndpoints']: [
          if std.objectHas(e, 'scheme') && e.scheme == 'https' then
            e {
              bearerTokenFile: '',
              tlsConfig+: {
                            certFile: '/etc/prometheus/secrets/metrics-client-certs/tls.crt',
                            keyFile: '/etc/prometheus/secrets/metrics-client-certs/tls.key',
                            insecureSkipVerify: false,
                          } +
                          if !(std.objectHas(o.metadata.labels, 'app.kubernetes.io/name') && o.metadata.labels['app.kubernetes.io/name'] == 'kubelet') then
                            {
                              caFile: '/etc/prometheus/configmaps/serving-certs-ca-bundle/service-ca.crt',
                              serverName: std.format('%s.%s.svc', [if o.metadata.name != 'thanos-sidecar' then o.metadata.name else 'prometheus-k8-' + o.metadata.name, o.metadata.namespace]),
                            }
                          else
                            {},
            }
          else
            e
          for e in super.endpoints
        ],
      },
    },
    [k]: configureAuthentication(o[k])
    for k in std.objectFieldsAll(o)
  },
}
