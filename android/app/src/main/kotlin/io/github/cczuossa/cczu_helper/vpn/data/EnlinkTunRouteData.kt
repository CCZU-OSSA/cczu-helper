package io.github.cczuossa.cczu_helper.vpn.data

import io.github.cczuossa.cczu_helper.vpn.protocol.packet.TransportProtocol

data class EnlinkTunRouteData(
    val address: String,
    val mask: Int = 32,
    val port: Int = 0,
    val protocol: TransportProtocol = TransportProtocol.TCP,
)
