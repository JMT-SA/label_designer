# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

class LabelDesigner < Roda
  # route 'publish', 'labels' do |r|
  route 'publish', 'labels' do |r|
    # BATCH PUBLISH
    # --------------------------------------------------------------------------
    # interactor = LabelApp::PublishInteractor.new(current_user, {}, { route_url: request.path }, {})

    r.on 'batch' do
      r.is do
        show_page { Labels::Publish::Batch::Targets.call }
        # (If coming from "BACK" button, show plain section using cached list of targets
      end

      r.get 'show_targets' do
        show_partial { Labels::Publish::Batch::SelectTargets.call }
      end

      r.post 'select_labels' do
        store = LocalStore.new(current_user.id)
        store.write(:lbl_publish_steps, printer_type: params[:batch][:printer_type], targets: params[:batch][:target_destinations])
        show_page { Labels::Publish::Batch::SelectLabels.call(store.read(:lbl_publish_steps)) }
        # VALIDATE: 1) printer chosen; 2) Server chosen, 3) Chosen server is configured for the chosen printer.
        # Store params in step (selected targets)
        # Get list of ELIGIBLE labels (approved) with publish history (Show date updated - max published date as days since published)
      end

      r.post 'publish' do
        ids = multiselect_grid_choices(params)
        store = LocalStore.new(current_user.id)
        current = store.read(:lbl_publish_steps)
        store.write(:lbl_publish_steps, current.merge(label_ids: ids))
        show_page { Labels::Publish::Batch::Publish.call(store.read(:lbl_publish_steps)) }
      end

      r.get 'send' do
        interactor = LabelApp::LabelInteractor.new(current_user, {}, { route_url: request.path }, {})
        # sleep 0.5
        store = LocalStore.new(current_user.id)
        # store.write(:testing_testing, 3)
        res = interactor.publish_labels(store.read(:lbl_publish_steps))
        # res = interactor.dummy
        show_partial { Labels::Publish::Batch::Send.call(res) }
      end

      r.get 'feedback' do
        return_json_response
        interactor = LabelApp::LabelInteractor.new(current_user, {}, { route_url: request.path }, {})
        # sleep 1
        store = LocalStore.new(current_user.id)
        # cnt = store.read(:testing_testing)
        # if cnt.positive?
        #   store.write(:testing_testing, cnt - 1)
        #   { updateMessage: { content: "<div class='relative w-100'><div class='absolute-fill tr mr5 pr5'><span style='text-align:right;font-size:22px;font-weight:bold;margin-right:1em'>Countdown: </span><span style='text-align:right;font-size:48px;font-weight:bold'>#{cnt}</span></div></div>", continuePolling: true } }.to_json
        # else
        #   store.delete(:testing_testing)
        #   # { updateMessage: { content: '<div class="relative w-100"><div class="absolute-fill tr mr5 pr5"><span style="color:blue;font-size:22px;font-weight:bold">All done now!</span></div></div>', finaliseProgressStep: 'cbl-current-step', continuePolling: false } }.to_json
        #   { updateMessage: { content: '<div class="relative w-100"><div class="absolute-fill tr mr5 pr5"><span style="color:blue;font-size:22px;font-weight:bold">All done now!</span></div></div>', finaliseProgressStep: 'cbl-current-step' } }.to_json
        # end
        res = interactor.publishing_status(store.read(:lbl_publish_steps))
        # TODO: differentiate between failure and exception - exception should stop polling...
        if res.success
          payload = { content: res.instance.body.to_s, continuePolling: !res.instance.done }
          payload[:finaliseProgressStep] = 'cbl-current-step' if res.instance.done
          { updateMessage: payload }.to_json
        else
          # Need to check res.instance - 204 means nothing sent yet; 404 means invalid file sent.
          { updateMessage: { content: res.message, continuePolling: true } }.to_json
        end
      end
    end

    # Progress/steps/wizard... Multi-step process
    # Wrapper in Interactors that reads & writes state using LocalStore.
    # Surfaces methods: steps, state_display, store_params(params, step no), final_id
    # Send final_id to Layout so that it can be targeted to go to fully-finished.
  end
end
# rubocop:enable Metrics/BlockLength
