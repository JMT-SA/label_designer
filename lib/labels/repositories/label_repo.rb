# frozen_string_literal: true

module LabelApp
  class LabelRepo < BaseRepo
    crud_calls_for :labels, name: :label, wrapper: Label
    crud_calls_for :multi_labels, name: :multi_label

    def sub_label_list(sub_label_ids)
      DB[:labels].select(:id, :label_name)
                 .where(id: sub_label_ids)
                 .map { |r| [r[:label_name], r[:id]] }
    end

    def link_multi_label(id, sub_label_ids)
      DB.transaction do
        DB[:multi_labels].where(label_id: id).delete

        sub_label_ids.split(',').each_with_index do |sub_label_id, index|
          create_multi_label(label_id: id,
                             sub_label_id: sub_label_id,
                             print_sequence: index + 1)
        end
      end
    end

    def delete_label_with_sub_labels(id)
      DB.transaction do
        DB[:multi_labels].where(label_id: id).delete
        delete_label(id)
      end
    end

    def no_sub_labels(id)
      DB[:multi_labels].where(label_id: id).count
    end

    def sub_label_ids(id)
      DB[:multi_labels].where(label_id: id).order(:print_sequence).select_map(:sub_label_id)
    end
  end
end
