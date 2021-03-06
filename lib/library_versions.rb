# frozen_string_literal: true

class LibraryVersions
  attr_reader :requested_libs

  LIB_STRATEGIES = {
    layout: [:gemver, 'Crossbeams::Layout'],
    dataminer: [:gemver, 'Crossbeams::Dataminer'],
    label_designer: [:gemver, 'Crossbeams::LabelDesigner'],
    rackmid: [:gemver, 'Crossbeams::RackMiddleware'],
    datagrid: [:gemver, 'Roda::DataGrid'],
    ag_grid: %i[jsver ag_grid],
    selectr: %i[jsver selectr],
    choices: %i[jsver choices],
    sweetalert: %i[jsver sweetalert],
    sortable: %i[jsver sortable],
    konva: %i[jsver konva],
    multi: %i[jsver multi],
    jasper: %i[jasper jasper]
  }.freeze

  # Javascript strategies - use send to call private methods.
  JS_STRATEGY = {
    ag_grid: ->(s) { s.send :ag_grid_version },
    selectr: ->(s) { s.send :selectr_version },
    choices: ->(s) { s.send :choices_version },
    sweetalert: ->(s) { s.send :sweetalert_version },
    sortable: ->(s) { s.send :sortable_version },
    konva: ->(s) { s.send :konva_version },
    multi: ->(s) { s.send :multi_version }
  }.freeze

  def initialize(*requested_libs)
    @requested_libs = requested_libs
  end

  def columns
    %i[library version]
  end

  def to_a
    version_list = requested_libs.map { |r| resolve(r) }
    version_list.unshift(format_lib('Application', ENV['VERSION']))
    version_list
  end

  private

  def resolve(lib)
    send(*LIB_STRATEGIES[lib])
  end

  def format_lib(lib, version)
    { library: lib, version: version }
  end

  def gemver(klass)
    format_lib(klass, Object.const_get(klass).const_get('VERSION'))
  end

  def jasper(_)
    return { library: 'Jruby Jasper', version: 'not checked during test' } if AppConst.test?

    repo = DevelopmentApp::JasperReportRepo.new
    { library: 'Jruby Jasper', version: repo.jasper_version }
  rescue StandardError => e
    { library: 'Jruby Jasper', version: e.message }
  end

  def jsver(key)
    js_strategy = JS_STRATEGY[key]
    return format_lib('Unknown directive', key) if js_strategy.nil?

    js_strategy.call(self)
  end

  def ag_grid_version
    lines = File.readlines('public/js/ag-grid-enterprise.min.js', encoding: 'UTF-8')
    l1 = lines.first
    ver = if l1.start_with?('/**')
            lines[2].chomp.split(' v').last
          else
            l1.chomp.split(' v').last
          end
    format_lib('AG-Grid', ver)
  end

  def selectr_version
    format_lib('Selectr', File.readlines('public/js/selectr.min.js', encoding: 'UTF-8')[1].chomp.split(' ').last)
  end

  def choices_version
    format_lib('Choices', File.readlines('public/js/choices.min.js', encoding: 'UTF-8').first.chomp.split(' v').last.split(' |').first)
  end

  def sweetalert_version
    s = File.read('public/js/sweetalert2.min.js', encoding: 'UTF-8')
    m = s.match(/\.version="(.+)"/)
    format_lib('Sweet Alert2', m.nil? ? 'UNKNOWN' : m[1])
  end

  def sortable_version
    m = File.readlines('public/js/Sortable.min.js', encoding: 'UTF-8').first.match(/Sortable (.+) - MIT/)
    format_lib('Sortable', m.nil? ? 'UNKNOWN' : m[1])
  end

  def konva_version
    src = File.readlines('public/js/konva.min.js', encoding: 'UTF-8')
    str = src[1].chomp.split(' v').last
    str = src[2].chomp.split(' v').last if str =~ %r{/*}
    format_lib('Konva', str)
  end

  def multi_version
    m = File.readlines('public/js/multi.min.js', encoding: 'UTF-8').first.match(/multi.js (.+) /)
    format_lib('Multi', m.nil? ? 'UNKNOWN' : m[1])
  end
end
