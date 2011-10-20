class Rails::Railtie::Configuration
  # Adds compass configuration accessor to the application configuration.
  #
  # If a configuration file for compass exists, it will be read in and
  # the project's configuration values will already be set on the config
  # object.
  #
  # For example:
  #
  #     module MyApp
  #       class Application < Rails::Application
  #          config.compass.line_comments = !Rails.env.production?
  #          config.compass.fonts_dir = "app/assets/fonts"
  #       end
  #     end
  #
  # It is suggested that you create a compass configuration file if you
  # want a quicker boot time when using the compass command line tool.
  #
  # For more information on available configuration options see:
  # http://compass-style.org/help/tutorials/configuration-reference/
  def asset_sync
    AssetSync.config
  end
end
