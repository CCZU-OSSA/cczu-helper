package io.github.cczuossa.cczu_helper.vpn.protocol.packet

import java.nio.ByteBuffer

/*
tcpHeader = TCPHeader{
        sourcePort = 45476,
        destinationPort = 80,
        sequenceNumber = 3648124082,
        acknowledgementNumber = 3879581804,
        headerLength = 32,
        window = 131,
        checksum = 31288,
        flags = ACK
    }

 */
data class UDPHeader(
    var sourcePort: Int = 0,
    var checksum: Int = 0,
    var destinationPort: Int = 0,
    var length: Int = 0

    ) {

    fun from(buffer: ByteBuffer) {
        this.sourcePort = buffer.getShort().toUShort().toInt()
        this.destinationPort = buffer.getShort().toUShort().toInt()
        this.length = buffer.getShort().toUShort().toInt()
        this.checksum = buffer.getShort().toUShort().toInt()
    }

    fun fill(buffer: ByteBuffer) {
        buffer.putShort(this.sourcePort.toShort())
        buffer.putShort(this.destinationPort.toShort())
        buffer.putShort(this.length.toShort())
        buffer.putShort(this.checksum.toShort())
    }


}