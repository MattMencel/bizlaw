# frozen_string_literal: true

module Demo
  # Buying one Action off the Case's menu — the first thing in this app that
  # writes, and the shape every act after it follows.
  #
  # What arrives is a `kind` and nothing else. The price the student read was
  # rendered from `Days::Command.quote` on the page that posted this, and it is
  # as old as that page; `apply` builds its own quote inside the request that
  # charges, so a stale slip can only ever be *refused* here, never charged a
  # different number than the one he agreed to. A price crossing the wire would
  # give that number a second author.
  #
  # A refusal is the game telling him something, so it is carried back as the
  # engine's own symbol on the flash and turned into a sentence by
  # `WorkingDraft` — the one place in this app that knows what a refusal reads
  # like. A controller writing prose into the flash would fork that vocabulary
  # on the first act that used it.
  #
  # A `kind` the Case never authored is a caller with a menu the engine never
  # offered rather than a refusal a student should see. It is the reader's doing
  # — nothing on the page can produce it — so it is a 404, which is what the
  # `ArgumentError` it shares with a mistyped seat is already read as.
  class SpendsController < SeatedController
    def create
      seated = resolve
      return if performed?

      Days::Command.apply(
        act: :spend,
        side: seated.side,
        day: sitting_day(seated.side.simulation),
        by: seated.user,
        kind: params[:kind]
      )

      redirect_to draft_path(seated)
    rescue Days::Command::Refused => e
      # Both halves, because the line that carries the stamp is found by kind
      # and the sentence under it is named by the reason. A page handed one
      # without the other has a refusal it cannot place or cannot read.
      flash[:spend_refusal] = {"kind" => params[:kind].to_s, "reason" => e.quote.refusal.to_s}
      redirect_to draft_path(seated)
    rescue ArgumentError
      no_page
    end
  end
end
