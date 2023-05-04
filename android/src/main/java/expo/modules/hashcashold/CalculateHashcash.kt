package expo.modules.hashcashold

import android.annotation.SuppressLint
import java.security.MessageDigest
import java.util.*
import java.text.SimpleDateFormat
import java.util.concurrent.atomic.AtomicLong
import kotlin.math.*
import kotlin.*
import kotlin.concurrent.thread

private fun salt(length: Int): String {
    val allowedChars = ('A'..'Z') + ('a'..'z') + ('0'..'9') + '+' + '/'
    return (1..length)
        .map { allowedChars.random() }
        .joinToString("")
}


@SuppressLint("SimpleDateFormat")
@OptIn(ExperimentalUnsignedTypes::class)
fun calculateHashcashMulti(k: UInt, identifier: String): String {
    val dateFormat = SimpleDateFormat("yyMMdd")

    val now = Calendar.getInstance(TimeZone.getTimeZone("GMT"))
    val ts = dateFormat.format(now.time)

    val challenge = "1:$k:$ts:$identifier::${salt(16)}:"

    val binaryDigitsToConsider = ceil((k.toDouble() / 8.0)).toInt()
    val limitBeginningSetBits = binaryDigitsToConsider * 8 - k.toInt()
    val limitBeginningNum = round(2.0.pow(limitBeginningSetBits.toDouble())).toInt().toUByte()

    val limitBeginning = UByteArray(binaryDigitsToConsider)
    limitBeginning[binaryDigitsToConsider-1] = limitBeginningNum

    var processorCount = Runtime.getRuntime().availableProcessors()
    if (processorCount < 1){
        processorCount = 4
    }
    val threadCount: Int = processorCount

    val threadCountLog = floor(log2(threadCount.toDouble())).toInt()
    val iterationPerThreadPerRound = 1.0.toLong() shl (k.toInt() - 5 - threadCountLog)

    val lastCounterEnd = AtomicLong(0)

    val results = ArrayList<String>()
    val threads = ArrayList<Thread>()

    for (threadIndex in 0 until threadCount) {
        results.add("")

        threads.add(thread(start = true, priority = 10) {
            val hashInstance = MessageDigest.getInstance("SHA-256")
            val builder = StringBuilder(challenge.length + k.toInt())
            builder.append(challenge)

            var currByte: UByte
            while(true){
                val counterStart = lastCounterEnd.getAndAdd(iterationPerThreadPerRound)

                if(counterStart < 0){
                    results[threadIndex] = ""
                    return@thread
                }

                val counterEnd = counterStart + iterationPerThreadPerRound

                val range: LongRange = counterStart until counterEnd
                for (counter: Long in range) {
                    builder.delete(challenge.length, builder.length)
                    builder.append(counter)

                    hashInstance.reset()
                    val hash = hashInstance.digest(builder.toString().toByteArray())

                    for (i in 0 until binaryDigitsToConsider) {
                        currByte = hash[i].toUByte()
                        if (currByte > limitBeginning[i]) {
                            break
                        } else if (currByte < limitBeginning[i]) {
                            lastCounterEnd.set((1.0.toLong() shl 47) * -1)
                            results[threadIndex] = builder.toString()
                            return@thread
                        }
                    }
                }
            }

        })
    }

    for (threadIndex in 0 until threadCount) {
        threads[threadIndex].join()
    }

    for (threadIndex in 0 until threadCount) {
        if (results[threadIndex] != "") {
            return results[threadIndex]
        }
    }

    return "" // we will never reach here.
}


@SuppressLint("SimpleDateFormat")
@OptIn(ExperimentalUnsignedTypes::class)
fun calculateHashcashSequential(k: UInt, identifier: String): String {
    val dateFormat = SimpleDateFormat("yyMMdd")

    val now = Calendar.getInstance(TimeZone.getTimeZone("GMT"))
    val ts = dateFormat.format(now.time)

    val challenge = "1:$k:$ts:$identifier::${salt(16)}:"

    val binaryDigitsToConsider = ceil((k.toDouble() / 8.0)).toInt()
    val limitBeginningSetBits = binaryDigitsToConsider * 8 - k.toInt()
    val limitBeginningNum = round(2.0.pow(limitBeginningSetBits.toDouble())).toInt().toUByte()

    val limitBeginning = UByteArray(binaryDigitsToConsider)
    limitBeginning[binaryDigitsToConsider-1] = limitBeginningNum

    var counter = 0

    val hashInstance = MessageDigest.getInstance("SHA-256")
    val builder = StringBuilder(challenge.length + k.toInt())
    builder.append(challenge)

    var currByte: UByte

    while (true) {
        builder.delete(challenge.length, builder.length)
        builder.append(counter)

        hashInstance.reset()
        val hash = hashInstance.digest(builder.toString().toByteArray())

        for (i in 0 until binaryDigitsToConsider) {
            currByte = hash[i].toUByte()
            if (currByte > limitBeginning[i]) {
                break
            } else if (currByte < limitBeginning[i]) {
                return "$challenge$counter"
            }
        }

        counter += 1
    }

}