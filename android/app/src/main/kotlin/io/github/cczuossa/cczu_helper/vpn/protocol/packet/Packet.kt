package io.github.cczuossa.cczu_helper.vpn.protocol.packet

import java.nio.ByteBuffer
import java.nio.charset.StandardCharsets

data class Packet(val buffer: ByteBuffer) {
    private val IP4_HEADER_SIZE = 20
    private val TCP_HEADER_SIZE = 20
    private val UDP_HEADER_SIZE = 8
    var tcpHeader: TCPHeader = TCPHeader()
    var udpHeader: UDPHeader = UDPHeader()
    var ip4Header: IP4Header = IP4Header()

    init {
        ip4Header.from(buffer)
        if (ip4Header.protocol == TransportProtocol.TCP) {
            tcpHeader.from(buffer)
        } else if (ip4Header.protocol == TransportProtocol.UDP) {
            udpHeader.from(buffer)
        }
    }

    override fun toString(): String {
        val data = ByteArray(buffer.remaining())
        buffer.get(data)
        return "ipcHeader($ip4Header),tcpHeader($tcpHeader),udpHeader($udpHeader),data(${
            data.toString(
                StandardCharsets.UTF_8
            )
        })"
    }
}