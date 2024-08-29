package io.github.cczuossa.cczu_helper.vpn.protocol.packet

import java.net.InetAddress
import java.nio.ByteBuffer
import kotlin.experimental.and

/*
Packet{
    ip4Header = IP4Header {
        version = 4,
        IHL = 5,
        typeOfService = 0,
        totalLength = 52,
        identificationAndFlagsAndFragmentOffset = -659668992,
        TTL = 64, protocol = 6:TCP,
        headerChecksum = 10686,
        sourceAddress = 1.1.33.178,
        destinationAddress = 211.65.66.99
    }, payloadSize = 1996
}

 */

data class IP4Header(

    var typeOfService: Short = 0,
    var headerChecksum: Int = 0,
    var headerLength: Int = 0,
    var IHL: Byte = 0,
    var TTL: Short = 0,
    var version: Byte = 0,
    var identificationAndFlagsAndFragmentOffset: Int = 0,
    var optionsAndPadding: Int = 0,
    var totalLength: Int = 0,
    var destinationAddress: InetAddress = InetAddress.getLocalHost(),
    var sourceAddress: InetAddress = InetAddress.getLocalHost(),
    var originalDestinationAddress: InetAddress? = null,
    var protocol: TransportProtocol = TransportProtocol.TCP,
    var protocolNum: Int = protocol.number(),

    ) {


    fun from(buffer: ByteBuffer) {
        val byte = buffer.get()
        this.version = (byte.toInt() shr 4).toByte()
        this.IHL = (byte and 15)
        this.headerLength = this.IHL.toInt() shl 2
        this.typeOfService = buffer.get().toUByte().toShort()
        this.totalLength = buffer.getShort().toUShort().toInt()
        this.identificationAndFlagsAndFragmentOffset = buffer.getInt()
        this.TTL = buffer.get().toUByte().toShort()
        this.protocolNum = buffer.get().toUByte().toShort().toInt()
        this.protocol = TransportProtocol.from(this.protocolNum)
        this.headerChecksum = buffer.getShort().toUShort().toInt()
        val data = ByteArray(4)
        buffer.get(data, 0, 4)
        this.sourceAddress = InetAddress.getByAddress(data)
        buffer.get(data, 0, 4)
        this.destinationAddress = InetAddress.getByAddress(data)
    }

    fun fill(buffer: ByteBuffer) {
        buffer.put(((this.version.toInt() shl 4) or this.IHL.toInt()).toByte())
        buffer.put(this.typeOfService.toByte())
        buffer.putShort(this.totalLength.toShort())
        buffer.putInt(this.identificationAndFlagsAndFragmentOffset)
        buffer.put(this.TTL.toByte())
        buffer.put(this.protocol.number().toByte())
        buffer.putShort(this.headerChecksum.toShort())
        if (originalDestinationAddress != null) {
            buffer.put(originalDestinationAddress!!.address)
        } else {
            buffer.put(sourceAddress.address)
        }
        buffer.put(destinationAddress.address)
    }

}