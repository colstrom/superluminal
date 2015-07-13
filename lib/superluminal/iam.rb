require 'aws-sdk'
require 'multi_json'
require 'terminal-announce'
require_relative 'settings'

# Module for dealing with IAM.
module IdentityAccessManagement
  def self.api(region = Settings.default_region)
    @api ||= Aws::IAM::Client.new region: region
  end

  module UserPolicy
    def self.from_template(template, project: nil, settings: nil)
      policy = YAML.load_file "#{ settings.template_path }/#{ template }.yaml"
      policy['Statement'].each do |statement|
        statement['Resource'] = settings.environments.map do |environment|
          "arn:aws:s3:::#{ settings.s3.namespace }-#{ project }-#{ environment.name }#{ policy['Metadata']['resource_suffix'] }"
        end
      end
      policy.delete 'Metadata'
      return MultiJson.encode policy
    end

    def self.generate(project_name, settings, templates: ['s3/bucket', 's3/contents'])
      templates.map do |template|
        { name: template.gsub(/\//, '-'),
          document: from_template(template, project: project_name, settings: settings)
        }
      end
    end

    def self.upload(policy, named: nil, for_user: nil)
      IdentityAccessManagement.api.put_user_policy(
        user_name: for_user,
        policy_name: named,
        policy_document: policy
      )
    end
  end

  def self.create_user(user_name)
    api.create_user user_name: user_name
    Announce.success "#{ user_name } created."
    rescue Aws::IAM::Errors::EntityAlreadyExists
      Announce.success "#{ user_name } already exists."
  end

  def self.apply_policies(to_user: nil, for_project: nil)
    policies = UserPolicy.generate(for_project, Settings)
    policies.each do |policy|
      UserPolicy.upload policy[:document], named: policy[:name], for_user: to_user
      Announce.success "Applied policy #{ policy[:name] } to #{ to_user }."
    end
  end
end
