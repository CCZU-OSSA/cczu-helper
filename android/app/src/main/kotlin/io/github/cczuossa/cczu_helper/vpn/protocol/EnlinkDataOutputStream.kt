package li.mo.testvpn

import java.io.ByteArrayOutputStream
import java.io.OutputStream

class EnlinkDataOutputStream(val os: OutputStream) : ByteArrayOutputStream() {

    //1, 1, 0, 65, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 10, 50, 50, 48, 48, 48, 54, 48, 51, 48, 57, 2, 0, 36, 101, 50, 98, 48, 97, 48, 100, 55, 45, 50, 49, 50, 51, 45, 52, 98, 101, 51, 45, 56, 51, 101, 52, 45, 50, 99, 98, 98, 54, 56, 57, 102, 56, 51, 99, 101, -1
    //1, 1, 0, 65, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 10, 50, 50, 48, 48, 48, 54, 48, 51, 48, 57, 2, 0, 36, 101, 50, 98, 48, 97, 48, 100, 55, 45, 50, 49, 50, 51, 45, 52, 98, 101, 51, 45, 56, 51, 101, 52, 45, 50, 99, 98, 98, 54, 56, 57, 102, 56, 51, 99, 101, -1
    fun writeAuth(user: String, token: String) {
        val userData = user.encodeToByteArray()
        val tokenData = token.encodeToByteArray()
        // 写出版本
        write(byteArrayOf(1))
        // 写出proto
        write(byteArrayOf(1))
        // 写出长度
        writeShort(
            1 + 1 + 2 + 4 + 4 + 1 +
                    2 + 1 + userData.size +
                    2 + 1 + tokenData.size
        )
        // 写出4个0
        write(byteArrayOf(0, 0, 0, 0))
        // 写出 ELK_METHOD_STUN
        write(byteArrayOf(1, 0, 0, 0))
        // 写出 ELK_OPT_USERNAME
        write(byteArrayOf(1, 0))
        // 写出用户名长度
        write(byteArrayOf(userData.size.toByte()))
        // 写出用户名
        write(userData)
        // 写出 ELK_OPT_SESSID
        write(byteArrayOf(2, 0))
        // 写出token长度
        write(byteArrayOf(tokenData.size.toByte()))
        // 写出token
        write(tokenData)
        // 写出-1
        write(byteArrayOf(-1))
        //println("write")
        //println(toByteArray().contentToString())
        os.write(toByteArray())
        os.flush()
    }

    fun writeHeartBeat() {
        os.write(byteArrayOf(1, 1, 0, 12, 0, 0, 0, 0, 3, 0, 0, 0))
        os.flush()
    }

    fun writeData(data: ByteArray, read: Int) {

        // 写出自定义头
        write(byteArrayOf(1, 4))
        // 写出长度
        writeShort(read + 12)
        // 写出xid
        write(byteArrayOf(0, 0, 0, 0))
        // 写出appid
        writeInt(1)
        // 写出数据
        write(data, 0, read)
        //println("write data ${toByteArray().contentToString()}")
        os.write(toByteArray())

    }

    fun writeShort(s: Int) {
        write(byteArrayOf(((s shr 8) and 255).toByte(), (s and 255).toByte()))
    }

    fun writeInt(s: Int) {
        write(
            byteArrayOf(
                ((s shl 24) and 255).toByte(),
                ((s shl 16) and 255).toByte(),
                ((s shl 8) and 255).toByte(),
                (s and 255).toByte()
            )
        )
    }
}