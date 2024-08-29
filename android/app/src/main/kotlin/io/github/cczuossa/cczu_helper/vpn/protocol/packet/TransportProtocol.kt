package io.github.cczuossa.cczu_helper.vpn.protocol.packet

enum class TransportProtocol(val i: Int) {
    TCP(6),
    UDP(17),
    Other(255);

    open fun number(): Int {
        return i
    }

    companion object {
        @JvmStatic
        open fun from(i: Int): TransportProtocol {
            if (i == 6) return TCP
            if (i == 17) return UDP
            return Other
        }
    }
}