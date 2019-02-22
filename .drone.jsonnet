[{
  "kind": "pipeline",
  "name": "Build&Test",
  "steps": [
    {
      name: "store-cache",
      image: "chrishsieh/drone-volume-cache",
      environment: [
        {PLUGIN_MOUNT: "drone-ci"},
        {PLUGIN_REBUILD: "true"},
      ],
      volumes: [
        {
          name: "cache",
          path: "/cache",
        },
      ],
    },
  ],
  volumes: [
    {
      name: "cache",
      temp: "{}",
    },
  ],
}]
