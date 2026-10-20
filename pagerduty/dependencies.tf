# How the services depend on each other, and what users see them as. PagerDuty
# shows both on an incident (what else may be affected, and which public
# service is down), and its service standards expect every service to have at
# least one technical and one business service dependency.

locals {
  # Every pagerduty_service, by the key used below.
  services = {
    swg          = pagerduty_service.swg
    indexers     = pagerduty_service.indexers
    needle       = pagerduty_service.needle
    route_origin = pagerduty_service.route_origin
    bootstrap    = pagerduty_service.bootstrap
    content      = pagerduty_service.content
  }

  # dependent => supporting: the dependent fails when the supporting service
  # does.
  technical_dependencies = {
    # The gateway's delegated router is delegated-ipfs.dev, whose origin is
    # route-origin.
    swg_route_origin = { dependent = "swg", supporting = "route_origin" }
    # route-origin only forwards to needle.
    route_origin_needle = { dependent = "route_origin", supporting = "needle" }
    # needle asks cid.contact for providers, beside the DHT.
    needle_indexers = { dependent = "needle", supporting = "indexers" }
    # The content kubo bootstraps from the bootstrap peers.
    content_bootstrap = { dependent = "content", supporting = "bootstrap" }
  }

  # What users reach, and the services behind it.
  business_services = {
    delegated_routing = {
      name        = "delegated-ipfs.dev"
      description = "Delegated routing for IPFS clients and browsers: provider, peer and IPNS lookups over HTTP."
      services    = ["route_origin", "needle"]
    }
    cid_contact = {
      name        = "cid.contact"
      description = "The IPNI content index: which providers have a CID."
      services    = ["indexers"]
    }
    inbrowser = {
      name        = "inbrowser.link"
      description = "The Service Worker Gateway: IPFS content loaded and verified in the browser."
      services    = ["swg"]
    }
    bootstrap = {
      name        = "bootstrap.ipni.io"
      description = "Bootstrap peers new IPFS nodes dial to join the network, including the legacy bootstrap.libp2p.io PeerIDs."
      services    = ["bootstrap"]
    }
    websites = {
      name        = "IPFS Project websites"
      description = "ipfs.tech, its docs and the other IPFS Project sites, pinned on the IPFS network."
      services    = ["content"]
    }
  }

  business_dependencies = merge([
    for b, bs in local.business_services : {
      for s in bs.services : "${b}_${s}" => { business = b, service = s }
    }
  ]...)
}

resource "pagerduty_service_dependency" "technical" {
  for_each = local.technical_dependencies

  dependency {
    dependent_service {
      id   = local.services[each.value.dependent].id
      type = "service"
    }
    supporting_service {
      id   = local.services[each.value.supporting].id
      type = "service"
    }
  }
}

resource "pagerduty_business_service" "public" {
  for_each = local.business_services

  name        = each.value.name
  description = "${each.value.description} ${local.managed_by}"
}

resource "pagerduty_service_dependency" "business" {
  for_each = local.business_dependencies

  dependency {
    dependent_service {
      id   = pagerduty_business_service.public[each.value.business].id
      type = "business_service"
    }
    supporting_service {
      id   = local.services[each.value.service].id
      type = "service"
    }
  }
}
