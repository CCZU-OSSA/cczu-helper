package li.mo.testvpn

import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.nio.charset.StandardCharsets

class EnlinkDataInputStream(val ins: InputStream) : InputStream() {

    val dnsList = arrayListOf<String>()
    val gate = arrayListOf<String>()


    // 0
    fun authStatus(): Boolean {
        // 跳过10字节
        skip(10)
        // 判断验证状态
        val status = ByteArray(2)
        read(status)
        //println(status.contentToString())
        return status[0] == 0.toByte() && status[1] == 0.toByte()
    }

    // 1
    fun virtualMask(): Int {
        val status = ByteArray(3)
        read(status)
        //println(status.contentToString())
        if (status[0] == 12.toByte() && status[1] == 0.toByte() && status[2] == 4.toByte()) {
            // 虚拟ip获取成功
            val virtualAddress = IntArray(4)
            readInt(virtualAddress)
            //println(virtualAddress.contentToString())
            var len = 0
            var i2 = 0
            var i3 = 0
            for (i in 0 until 4) {
                val is1 = virtualAddress[i].toString(2)
                while (true) {
                    val indexof = is1.indexOf("1", i2)
                    if (indexof == -1) {
                        break
                    }
                    i2 = indexof + "1".length
                    i3++
                }
                len += i3
            }
            return len
        }
        return 32
    }

    // 2
    fun virtualAddress(): String {
        val status = ByteArray(3)
        read(status)
        //println(status.contentToString())
        if (status[0] == 11.toByte() && status[1] == 0.toByte() && status[2] == 4.toByte()) {
            // 虚拟掩码获取成功
            val virtualAddress = IntArray(4)
            readInt(virtualAddress)
            //println(virtualAddress.contentToString())
            return "${virtualAddress[0]}.${virtualAddress[1]}.${virtualAddress[2]}.${virtualAddress[3]}"
        }
        return "0.0.0.0"
    }

    // 3
    fun others() {

        while (true) {
            val status = ByteArray(2)
            read(status)
            //println(status.contentToString())
            if (status[0] != 43.toByte()) {
                // 读取更多东西
                params(status)
            } else break
        }
        // 未知数据
        // [1, 0, 53, 0, 16, -128, -100, 125, 0, 0, 0, 0, 0, 39, 114, 90, 0, 0, 0, 3, -37, 54, 0, 16, 16, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1]

    }

    // 4
    fun params(data: ByteArray) {
        if (data[0] == 35.toByte() && data[1] == 0.toByte()) {
            // 读取网关
            val len = read()
            //println(len)
            val gatewayData = IntArray(len)
            readInt(gatewayData)
            //println(gatewayData.contentToString())
            gate.add("${gatewayData[0]}.${gatewayData[1]}.${gatewayData[2]}.${gatewayData[3]}")
        }
        if (data[0] == 36.toByte() && data[1] == 0.toByte()) {
            // 读取DNS
            val len = read()
            //println(len)
            val dnsData = ByteArray(len)
            read(dnsData)
            //println(dnsData.contentToString())
            val dnsStr = dnsData.toString(StandardCharsets.UTF_8)
            val dnsList = dnsStr.replace("；", ";").split(';')
            //println(dnsList.toString())
            this.dnsList.addAll(dnsList)
        }
        if (data[0] == 37.toByte() && data[1] == 0.toByte()) {
            // 读取WINS
            val len = read()
            //println(len)
            val winsData = ByteArray(len)
            read(winsData)
            //println(winsData.contentToString())
            val winsStr = winsData.toString(StandardCharsets.UTF_8)
            val winsList = winsStr.replace("；", ";").split(';')
            //println(winsList.toString())
        }
    }

    fun readInt(intArray: IntArray) {
        val data = ByteArray(intArray.size)
        read(data)
        for (i in data.indices) {
            intArray[i] = (data[i].toInt() and 255)
        }
    }


    override fun read(): Int {
        return ins.read()
    }

    fun drop() {
        val byte = ByteArray(512)
        ins.read(byte)
        //println(byte.contentToString())
        //println(byte.toString(StandardCharsets.UTF_8))
    }

    fun readData(): ByteArray {
        val head = ByteArray(8)

        if (read(head) > 0) {
            // 1,4 开头为数据
            // 1,2 开头为心跳包
            //println("read head pack: ${head.contentToString()}")
            if (head[0].toInt() != 1 || head[1].toInt() != 2 || head[2].toInt() != 0 || head[3].toInt() != 10) {
                val len = (head[3].toInt() and 255) or (head[2].toInt() shl 8)
                val data = ByteArray(len - 8)
                if (read(data) > 0) {
                    //println("read pack$len:${data.contentToString()}")
                    return data
                }
            } else {
                read(ByteArray(2048))
            }
        }
        return ByteArray(0)

    }

}