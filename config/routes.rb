Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # The demo run, and the only screen there is. Declared outside production for
  # the same reason `demo:seed` aborts there: the rows this reads are laid down
  # by a rake task that resets its own Organization, and neither belongs on a
  # deployed instance.
  #
  # The seat is optional because the bare form is what `demo:seed` prints and
  # what the player is handed: it means his own seat, and naming it resolves to
  # the same page. The segment exists for the second tab, which acts as a
  # different person on the opposing Side — there is no authentication, no
  # session and no second live player, so the URL is the whole of what says who
  # is reading.
  unless Rails.env.production?
    get "demo/:run(/:seat)", to: "demo/runs#show", as: :demo_run
    # The spend, nested under the seat that takes it. The page never sends a
    # price — only which Action off the menu — because `Days::Command` quotes
    # inside the same request that charges, and a price crossing the wire would
    # be a second authority for a number this design keeps in one place.
    post "demo/:run(/:seat)/spends", to: "demo/spends#create", as: :demo_run_spends
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
