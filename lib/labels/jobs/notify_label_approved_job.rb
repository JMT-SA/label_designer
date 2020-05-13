# frozen_string_literal: true

module LabelApp
  # Called after a label has been approved.
  class NotifyLabelApprovedJob < BaseQueJob
    attr_reader :list, :label

    def run(label_id)
      build_list

      unless list.empty?
        lookup_label(label_id)

        mail_opts = {
          to: format_recipients,
          subject: "NSLD Label approved: #{label.label_name}",
          body: body
        }
        DevelopmentApp::SendMailJob.enqueue(mail_opts)
      end
      finish
    end

    private

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
  end
end
