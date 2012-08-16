require 'rails/generators'
require 'rails/generators/generated_attribute'

module Bootstrap
  module Generators
    class ThemedGenerator < ::Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)
      argument :controller_path,    :type => :string
      argument :model_name,         :type => :string, :required => false
      argument :layout,             :type => :string, :default => "application",
                                    :banner => "Specify application layout"

      def initialize(args, *options)
        super(args, *options)
        initialize_views_variables
      end

      def copy_views
        generate_views
      end

      protected

      def initialize_views_variables
        @base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth, @controller_namespace, @model_namespace = extract_modules(controller_path,model_name)
        @controller_routing_path = @controller_namespace ? "#{@controller_namespace}_#{@controller_routing_path}" : @controller_routing_path
        @controller_routing_path = @controller_file_path.gsub(/\//, '_')
        @model_name = @base_name.singularize.camelize unless @model_name
        @model_name = @model_name.camelize
        puts @controller_namespace.blank?
      end

      def controller_routing_path
        @controller_routing_path
      end

      def singular_controller_routing_path
        @controller_routing_path.singularize
      end

      def class_name
        @model_name
      end

      def plural_model_name
        @model_name.pluralize
      end

      def controller_namespace
        @controller_namespace ? @controller_namespace.to_s.downcase : nil
      end

      def model_namespace
        @model_namespace ? @model_namespace.constantize : nil
      end

      def resource_name
        @model_name.demodulize.downcase
      end

      def plural_resource_name
        resource_name.pluralize
      end

      def columns
        begin
          excluded_column_names = %w[id created_at updated_at]
          @model_name.constantize.columns.reject{|c| excluded_column_names.include?(c.name) }.collect{|c| ::Rails::Generators::GeneratedAttribute.new(c.name, c.type)}
        rescue NoMethodError
          @model_name.constantize.fields.collect{|c| c[1]}.reject{|c| excluded_column_names.include?(c.name) }.collect{|c| ::Rails::Generators::GeneratedAttribute.new(c.name, c.type.to_s)}
        end
      end

      def extract_modules(controller_name,model_name)
        controller_modules = controller_name.include?('/') ? controller_name.split('/') : controller_name.split('::')
        controller_name    = controller_modules.pop
        controller_namespace = controller_modules.map { |n| n.capitalize }.join("::")
        controller_path    = controller_modules.map { |m| m.underscore }
        file_path = (controller_path + [controller_name.underscore]).join('/')
        nesting = controller_modules.map { |m| m.camelize }.join('::')
        controller_namespace = nil if controller_namespace.blank?
        if model_name
          model_modules = model_name.include?('/') ? model_name.split('/') : model_name.split('::')
          model_name = model_modules.pop
          model_namespace = model_modules.map { |m| m.capitalize }.join("::")
        else
          model_namespace = nil
        end
        [controller_name, controller_path, file_path, nesting, controller_modules.size, controller_namespace, model_namespace]
      end

      def generate_views
        views = {
          "index.html.#{ext}"                 => File.join('app/views', @controller_file_path, "index.html.#{ext}"),
          "new.html.#{ext}"                   => File.join('app/views', @controller_file_path, "new.html.#{ext}"),
          "edit.html.#{ext}"                  => File.join('app/views', @controller_file_path, "edit.html.#{ext}"),
          "#{form_builder}_form.html.#{ext}"  => File.join('app/views', @controller_file_path, "_form.html.#{ext}"),
          "show.html.#{ext}"                  => File.join('app/views', @controller_file_path, "show.html.#{ext}")}
        selected_views = views
        options.engine == generate_erb(selected_views)
      end

      def generate_erb(views)
        views.each do |template_name, output_path|
          template template_name, output_path
        end
      end

      def ext
        ::Rails.application.config.generators.options[:rails][:template_engine] || :erb
      end

      def form_builder
        defined?(::SimpleForm) ? 'simple_form/' : ''
      end
    end
  end
end
