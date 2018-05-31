# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :phxwhttpoison, PhxwhttpoisonWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "hA/IheeyZBfaItgsgta9vnAz9KNOPl2Z+c/fi+55yPZJE9IiUAduIsTNoTOUa+Ey",
  render_errors: [view: PhxwhttpoisonWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Phxwhttpoison.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
