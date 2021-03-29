# frozen_string_literal: true

module LabelApp
  # Called after a label has been approved.
  class NotifyLabelApprovedJob < BaseQueJob
    attr_reader :list, :label, :approved, :reject_reason

    def run(label_id, approved, reject_reason)
      @approved = approved
      @reject_reason = reject_reason

      build_list

      unless list.empty?
        lookup_label(label_id)

        mail_opts = {
          to: format_recipients,
          subject: subject,
          body: body
        }
        DevelopmentApp::SendMailJob.enqueue(mail_opts)
      end
      finish
    end

    private

    def subject
      "NSLD Label #{approved ? 'approved' : 'rejected'}: #{label.label_name}"
    end

    def build_list
      repo = DevelopmentApp::UserRepo.new
      @list = repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_LABEL_PUBLISHERS).reject { |_, email| email.nil_or_empty? }
    end

    def lookup_label(label_id)
      @label_repo = LabelApp::LabelRepo.new
      @label = @label_repo.find_label(label_id)
    end

    def format_recipients
      list.map { |r| "#{r.first} <#{r.last}>" }
    end

    def body
      multi_labels = @label_repo.sub_label_belongs_to_names(label.id)
      return rejected_body unless approved

      approved_body(multi_labels)
    end

    def approved_body(multi_labels)
      if multi_labels.empty?
        <<~STR
          Label "#{label.label_name}" has been approved.

          It can now be published.
        STR
      else
        <<~STR
          Label "#{label.label_name}" has been approved.

          It can now be published.

          The following multi labels that depend on it should also be published:
          * #{multi_labels.join("\n* ")}
        STR
      end
    end

    def rejected_body
      <<~STR
        Label "#{label.label_name}" has been rejected.

        It needs to be re-edited and re-submitted for approval.

        #{reject_reason}
      STR
    end
  end
end
