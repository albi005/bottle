package hu.alb1.bottle.ui.icon

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

@Suppress("CheckReturnValue")
public val bluetooth_connected: ImageVector
  get() {
    if (_bluetooth_connected != null) {
      return _bluetooth_connected!!
    }
    _bluetooth_connected =
      ImageVector.Builder(
          name = "bluetooth_connected",
          defaultWidth = 20.dp,
          defaultHeight = 20.dp,
          viewportWidth = 20f,
          viewportHeight = 20f,
        )
        .apply {
          path(
            fill = SolidColor(Color.Black),
            fillAlpha = 1f,
            stroke = null,
            strokeAlpha = 1f,
            strokeLineWidth = 1f,
            strokeLineCap = StrokeCap.Butt,
            strokeLineJoin = StrokeJoin.Bevel,
            strokeLineMiter = 1f,
            pathFillType = PathFillType.Companion.NonZero,
          ) {
            moveTo(9f, 18f)
            verticalLineTo(12.13f)
            lineTo(5.44f, 15.69f)
            lineTo(4.38f, 14.63f)
            lineTo(9f, 10f)
            lineTo(4.38f, 5.38f)
            lineTo(5.44f, 4.31f)
            lineTo(9f, 7.88f)
            verticalLineTo(2f)
            horizontalLineToRelative(1.13f)
            lineToRelative(4.5f, 4.5f)
            lineTo(11.13f, 10f)
            lineToRelative(3.5f, 3.5f)
            lineTo(10.13f, 18f)
            horizontalLineTo(9f)
            close()
            moveTo(10.5f, 8.5f)
            lineToRelative(2f, -2f)
            lineToRelative(-2f, -2f)
            verticalLineToRelative(4f)
            close()
            moveToRelative(0f, 7f)
            lineToRelative(2f, -2f)
            lineToRelative(-2f, -2f)
            verticalLineToRelative(4f)
            close()
            moveTo(3.61f, 10.89f)
            quadTo(3.25f, 10.52f, 3.25f, 10f)
            reflectiveQuadTo(3.61f, 9.11f)
            reflectiveQuadTo(4.5f, 8.75f)
            reflectiveQuadTo(5.39f, 9.11f)
            reflectiveQuadTo(5.75f, 10f)
            reflectiveQuadTo(5.39f, 10.89f)
            reflectiveQuadTo(4.5f, 11.25f)
            reflectiveQuadTo(3.61f, 10.89f)
            close()
            moveToRelative(11f, 0f)
            quadTo(14.25f, 10.52f, 14.25f, 10f)
            reflectiveQuadTo(14.61f, 9.11f)
            reflectiveQuadTo(15.5f, 8.75f)
            reflectiveQuadToRelative(0.89f, 0.36f)
            reflectiveQuadTo(16.75f, 10f)
            reflectiveQuadToRelative(-0.36f, 0.89f)
            reflectiveQuadTo(15.5f, 11.25f)
            reflectiveQuadTo(14.61f, 10.89f)
            close()
          }
        }
        .build()
    return _bluetooth_connected!!
  }

private var _bluetooth_connected: ImageVector? = null
