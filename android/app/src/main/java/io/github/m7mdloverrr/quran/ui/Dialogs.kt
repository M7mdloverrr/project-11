package io.github.m7mdloverrr.quran.ui

import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.text.input.KeyboardType
import io.github.m7mdloverrr.quran.data.ar

private fun parseNumber(s: String): Int? =
    s.map { c -> if (c in '٠'..'٩') ('0' + (c - '٠')) else c }.joinToString("").trim().toIntOrNull()

@Composable
fun PageJumpDialog(onDismiss: () -> Unit, onGo: (Int) -> Unit) {
    var text by remember { mutableStateOf("") }
    val n = parseNumber(text)
    val valid = n != null && n in 1..604
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("الانتقال إلى صفحة") },
        text = {
            OutlinedTextField(
                value = text,
                onValueChange = { text = it.take(3) },
                label = { Text("رقم الصفحة (${1.ar()}–${604.ar()})") },
                singleLine = true,
                isError = text.isNotEmpty() && !valid,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            )
        },
        confirmButton = { TextButton(onClick = { n?.let(onGo) }, enabled = valid) { Text("انتقال") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("إلغاء") } },
    )
}
