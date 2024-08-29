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
data class TCPHeader(
    var acknowledgementNumber: Long = 0,
    var sequenceNumber: Long = 0,
    var sourcePort: Int = 0,
    var urgentPointer: Int = 0,
    var window: Int = 0,
    var checksum: Int = 0,
    var destinationPort: Int = 0,
    var originalDestinationPort: Int = 0,
    var headerLength: Int = 0,
    var dataOffsetAndReserved: Byte = 0,
    var flags: Byte = (16 or 16).toByte(),
    var optionsAndPadding: ByteArray = byteArrayOf(),

    ) {

    val ACK: Int = 16
    val FIN: Int = 1
    val PSH: Int = 8
    val RST: Int = 4
    val SYN: Int = 2
    val URG: Int = 32


    fun from(buffer: ByteBuffer) {
        this.originalDestinationPort = 0
        this.sourcePort = buffer.getShort().toUShort().toInt()
        this.destinationPort = buffer.getShort().toUShort().toInt()
        this.sequenceNumber = buffer.getInt().toUInt().toLong()
        this.acknowledgementNumber = buffer.getInt().toUInt().toLong()
        this.dataOffsetAndReserved = buffer.get()
        this.headerLength = (this.dataOffsetAndReserved.toInt() and 240) shr 2
        this.flags = buffer.get()
        this.window = buffer.getShort().toUShort().toInt()
        this.checksum = buffer.getShort().toUShort().toInt()
        this.urgentPointer = buffer.getShort().toUShort().toInt()
        val i = this.headerLength - 20
        if (i > 0) {
            ByteArray(i).also { this.optionsAndPadding = it }
            buffer.get(this.optionsAndPadding, 0, i)
        }
    }

    fun fill(buffer: ByteBuffer) {
        if (this.originalDestinationPort != 0) {
            buffer.putShort(this.originalDestinationPort.toShort())
        } else {
            buffer.putShort(this.sourcePort.toShort())
        }
        buffer.putShort(this.destinationPort.toShort())
        buffer.putInt(this.sequenceNumber.toInt())
        buffer.putInt(this.acknowledgementNumber.toInt())
        buffer.put(this.dataOffsetAndReserved)
        buffer.put(this.flags)
        buffer.putShort(this.window.toShort())
        buffer.putShort(this.checksum.toShort())
        buffer.putShort(this.urgentPointer.toShort())
    }

    fun isFIN(): Boolean {
        return (this.flags.toInt() and 1) == 1
    }

    fun isSYN(): Boolean {
        return (this.flags.toInt() and 2) == 2
    }

    fun isRST(): Boolean {
        return (this.flags.toInt() and 4) == 4
    }

    fun isPSH(): Boolean {
        return (this.flags.toInt() and 8) == 8
    }

    fun isACK(): Boolean {
        return (this.flags.toInt() and 16) == 16
    }

    fun isURG(): Boolean {
        return (this.flags.toInt() and 32) == 32
    }

}