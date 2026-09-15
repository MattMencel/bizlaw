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
    # The Instructor's minute, declared **above** the seated route because the
    # optional seat segment would otherwise swallow it. It is a route of its own
    # rather than a seat the draft renders differently: they are not in the
    # dispute, so what they are handed is a different instrument and not the
    # same one read from another chair.
    get "demo/:run/#{Demo::Seat::INSTRUCTOR}", to: "demo/minutes#show", as: :demo_run_minute
    # Releasing the Second for one Team for one Day. It carries the Side it is
    # granted to and the Day it is granted on, and nothing else — a waiver has
    # no cost, no quote and nothing to confirm, which is why it sits beside
    # `Days::Command` rather than inside it.
    post "demo/:run/#{Demo::Seat::INSTRUCTOR}/waivers",
      to: "demo/waivers#create", as: :demo_run_waivers

    get "demo/:run(/:seat)", to: "demo/runs#show", as: :demo_run
    # The spend, nested under the seat that takes it. The page never sends a
    # price — only which Action off the menu — because `Days::Command` quotes
    # inside the same request that charges, and a price crossing the wire would
    # be a second authority for a number this design keeps in one place.
    post "demo/:run(/:seat)/spends", to: "demo/spends#create", as: :demo_run_spends
    # Drawing the position, which is one act however much of it changed: the
    # Terms, the Exhibits riding them and the covering note all arrive together
    # and replace what was on the table. `Offers::Stage` is one seam because a
    # revision replaces a position rather than amending it, and the teammate who
    # Seconds confirms the whole play — so a wire that could move the Exhibits
    # without the Terms would be handing them half of it.
    #
    # It costs nothing and is ungated, so there is no confirmation and no price:
    # the only thing this can be refused for is a Day that ended underneath it.
    post "demo/:run(/:seat)/offers", to: "demo/offers#create", as: :demo_run_offers
    # Executing the draft. Like the spend it carries the Day it was quoted
    # against and no price, because it is the same seam charging it — and unlike
    # the spend it carries nothing else at all: `Days::Command` reads the
    # position off the table inside the transaction that charges, so what a
    # commit is *of* was settled by the act that put it there.
    #
    # It names no seconder. The gate this map opens is the Instructor's waiver,
    # and "one attributed plaintiff, forever" means `seconders_other_than`
    # answers nobody on every page the demo renders: a control naming a teammate
    # would be one no reader here could ever open.
    post "demo/:run(/:seat)/commits", to: "demo/commits#create", as: :demo_run_commits
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
