require 'aws-sdk'
require_relative 'settings'

# Module for dealing with VPCs
module VirtualPrivateCloud
  def self.api(region = Settings.default_region)
    @api ||= Aws::EC2::Client.new region: region
  end

  def self.find_vpcs_by_project(project)
    api.describe_vpcs(
      filters: [
        { name: 'tag:Project', values: [project] }
      ]
    ).vpcs
  end

  def self.find_vpcs(where: 'project', named:)
    method("find_vpcs_by_#{ where }").call(named)
  end

  def self.first_vpc(where: 'project', named:)
    find_vpcs(where: where, named: named).first
  end

  def self.attempt_peering(from_vpc:, to_vpc:)
    abort "VPC not found: #{from_vpc}" unless from = first_vpc(named: from_vpc)
    abort "VPC not found: #{to_vpc}" unless to = first_vpc(named: to_vpc)
    create_peering from: from, to: to
  end

  def self.create_peering(from:, to:)
    peering_id = request_peering from.vpc_id, to.vpc_id
    approve_peering_request with_id: peering_id
    create_routes from, to, using_connection: peering_id
  end

  def self.request_peering(from_vpc, to_vpc)
    response = api.create_vpc_peering_connection vpc_id: from_vpc, peer_vpc_id: to_vpc
    request_id = response.vpc_peering_connection.vpc_peering_connection_id
    Announce.success "Request #{ request_id } to peer #{ from_vpc } with #{ to_vpc }." # TODO: Use names, not IDs! Tags should *mean* something.
    assign_name "#{ from_vpc }-#{ to_vpc }", to: request_id # TODO: Assigning tags is not requesting peering. This line does not belong here.
  end

  def self.approve_peering_request(with_id:)
    api.accept_vpc_peering_connection vpc_peering_connection_id: with_id
    Announce.success "Approved peering request #{ with_id }."
    rescue Aws::EC2::Errors::VpcPeeringConnectionAlreadyExists
      Announce.success "Redundant peering request #{ with_id }, deleting."
      delete_peering_request with_id
  end

  def self.delete_peering_request(request_id)
    api.delete_vpc_peering_connection vpc_peering_connection_id: request_id
    Announce.success "Peering request #{ request_id } deleted."
  end

  def self.find_route_tables_by_peering(peering_id)
    api.describe_route_tables(
      filters: [
        { name: 'route.vpc-peering-connection-id', values: [peering_id] }
      ]
    ).route_tables
  end

  def self.find_route_tables_by_vpc(vpc_id)
    api.describe_route_tables(
      filters: [
        { name: 'vpc-id', values: [vpc_id] },
        { name: 'association.main', values: ['false'] }
      ]
    ).route_tables
  end

  def self.find_route_tables(where: 'vpc', **options)
    method("find_route_tables_by_#{ where }").call options[where.to_sym]
  end

  def self.create_routes(from_vpc, to_vpc, using_connection:)
    create_route from_vpc, to_vpc, using_connection
    create_route to_vpc, from_vpc, using_connection
  end

  def self.create_route(from, to, peering_id)
    route_tables = find_route_tables where: 'vpc', vpc: from.vpc_id
    route_tables.each do |route_table|
      api.create_route(
        route_table_id: route_table.route_table_id,
        destination_cidr_block: to.cidr_block,
        vpc_peering_connection_id: peering_id
      )
    end
    Announce.success "Routes created from #{ from.vpc_id } to #{ to.vpc_id } using #{ peering_id }."
    rescue Aws::EC2::Errors::RouteAlreadyExists
      Announce.success "Already have a route connecting #{ from.vpc_id } to #{ to.vpc_id } using #{ peering_id }."
  end

  def self.assign_name(name, to:)
    api.create_tags resources: [to], tags: [{ key: 'Name', value: name }]
    Announce.success "Assigned tag #{ name } to #{ to }."
    return to
  end
end
