# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module LabelApp
  class TestLabelPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        label_name: 'ABC',
        label_json: {},
        label_dimension: '100x100',
        px_per_mm: '8',
        variable_xml: '',
        png_image: '',
        container_type: '',
        commodity: '',
        market: '',
        language: '',
        category: '',
        sub_category: '',
        multi_label: false,
        sample_data: {},
        variable_set: 'CMS',
        created_by: 'ABC',
        updated_by: 'ABC',
        completed: false,
        approved: false,
        extended_columns: {}
      }
      LabelApp::Label.new(base_attrs.merge(attrs))
    end

    def test_create
      res = LabelApp::TaskPermissionCheck::Label.call(:create)
      assert res.success, 'Should always be able to create a label'
    end

    def test_edit
      LabelApp::LabelRepo.any_instance.stubs(:find_label).returns(entity)
      res = LabelApp::TaskPermissionCheck::Label.call(:edit, 1)
      assert res.success, 'Should be able to edit a label'

      LabelApp::LabelRepo.any_instance.stubs(:find_label).returns(entity(completed: true))
      res = LabelApp::TaskPermissionCheck::Label.call(:edit, 1)
      refute res.success, 'Should not be able to edit a completed label'
    end

    def test_delete
      LabelApp::LabelRepo.any_instance.stubs(:find_label).returns(entity)
      res = LabelApp::TaskPermissionCheck::Label.call(:delete, 1)
      assert res.success, 'Should be able to delete a label'

      LabelApp::LabelRepo.any_instance.stubs(:find_label).returns(entity(completed: true))
      res = LabelApp::TaskPermissionCheck::Label.call(:delete, 1)
      refute res.success, 'Should not be able to delete a completed label'
    end

    def test_complete
      LabelApp::LabelRepo.any_instance.stubs(:find_label).returns(entity)
      res = LabelApp::TaskPermissionCheck::Label.call(:complete, 1)
      assert res.success, 'Should be able to complete a label'

      LabelApp::LabelRepo.any_instance.stubs(:find_label).returns(entity(completed: true))
      res = LabelApp::TaskPermissionCheck::Label.call(:complete, 1)
      refute res.success, 'Should not be able to complete an already completed label'
    end

    def test_approve
      LabelApp::LabelRepo.any_instance.stubs(:find_label).returns(entity(completed: true, approved: false))
      res = LabelApp::TaskPermissionCheck::Label.call(:approve, 1)
      assert res.success, 'Should be able to approve a completed label'

      LabelApp::LabelRepo.any_instance.stubs(:find_label).returns(entity)
      res = LabelApp::TaskPermissionCheck::Label.call(:approve, 1)
      refute res.success, 'Should not be able to approve a non-completed label'

      LabelApp::LabelRepo.any_instance.stubs(:find_label).returns(entity(completed: true, approved: true))
      res = LabelApp::TaskPermissionCheck::Label.call(:approve, 1)
      refute res.success, 'Should not be able to approve an already approved label'
    end

    def test_reopen
      LabelApp::LabelRepo.any_instance.stubs(:find_label).returns(entity)
      res = LabelApp::TaskPermissionCheck::Label.call(:reopen, 1)
      refute res.success, 'Should not be able to reopen a label that has not been approved'

      LabelApp::LabelRepo.any_instance.stubs(:find_label).returns(entity(completed: true, approved: true))
      res = LabelApp::TaskPermissionCheck::Label.call(:reopen, 1)
      assert res.success, 'Should be able to reopen an approved label'
    end
  end
end
