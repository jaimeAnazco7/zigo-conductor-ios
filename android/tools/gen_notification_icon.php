<?php
/**
 * Genera ic_stat_onesignal_default.png desde el logo actual (ic_launcher_foreground).
 * Usa escala de grises + transparencia suave (mejor definición que blanco/negro duro).
 * Android usa el canal alpha; el gris ayuda a visualizarlo en el editor.
 */
$srcPath = __DIR__ . '/../app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png';
$resBase = __DIR__ . '/../app/src/main/res';
$previewPath = __DIR__ . '/ic_stat_onesignal_preview_grayscale.png';

$sizes = [
    'mdpi' => 24,
    'hdpi' => 36,
    'xhdpi' => 48,
    'xxhdpi' => 72,
    'xxxhdpi' => 96,
];

function logoStrength(int $r, int $g, int $b, int $a): float
{
    if ($a >= 100) {
        return 0.0;
    }

    $lum = 0.299 * $r + 0.587 * $g + 0.114 * $b;
    $cyan = min(1.0, max(0.0, (($g - 70) / 130) + (($b - 50) / 130) - ($r / 220)));
    $orange = min(1.0, max(0.0, (($r - 90) / 110) + (($g - 70) / 160)));
    $bright = min(1.0, max(0.0, ($lum - 45) / 170));
    $ring = min(1.0, max(0.0, ($lum - 30) / 55));

    return max($cyan, $orange, $bright, $ring * 0.75);
}

function renderIcon($src, int $size): GdImage
{
    $sw = imagesx($src);
    $sh = imagesy($src);

    // Render a mayor resolución y reducir = bordes más suaves
    $workSize = $size * 4;
    $work = imagecreatetruecolor($workSize, $workSize);
    imagealphablending($work, false);
    imagesavealpha($work, true);
    $transparent = imagecolorallocatealpha($work, 0, 0, 0, 127);
    imagefill($work, 0, 0, $transparent);

    imagecopyresampled($work, $src, 0, 0, 0, 0, $workSize, $workSize, $sw, $sh);

    for ($y = 0; $y < $workSize; $y++) {
        for ($x = 0; $x < $workSize; $x++) {
            $rgba = imagecolorat($work, $x, $y);
            $a = ($rgba >> 24) & 0x7F;
            $r = ($rgba >> 16) & 0xFF;
            $g = ($rgba >> 8) & 0xFF;
            $b = $rgba & 0xFF;

            $strength = logoStrength($r, $g, $b, $a);
            if ($strength < 0.04) {
                imagesetpixel($work, $x, $y, $transparent);
                continue;
            }

            $strength = min(1.0, $strength);
            $alpha = 127 - (int) round($strength * 127);
            $gray = (int) round(160 + (95 * $strength)); // gris claro → blanco
            $color = imagecolorallocatealpha($work, $gray, $gray, $gray, $alpha);
            imagesetpixel($work, $x, $y, $color);
        }
    }

    $dst = imagecreatetruecolor($size, $size);
    imagealphablending($dst, false);
    imagesavealpha($dst, true);
    imagefill($dst, 0, 0, $transparent);
    imagecopyresampled($dst, $work, 0, 0, 0, 0, $size, $size, $workSize, $workSize);
    imagedestroy($work);

    return $dst;
}

$src = @imagecreatefrompng($srcPath);
if (!$src) {
    fwrite(STDERR, "No se pudo leer: $srcPath\n");
    exit(1);
}

foreach ($sizes as $folder => $size) {
    $dst = renderIcon($src, $size);
    $dir = $resBase . '/drawable-' . $folder;
    if (!is_dir($dir)) {
        mkdir($dir, 0777, true);
    }
    $out = $dir . '/ic_stat_onesignal_default.png';
    imagepng($dst, $out);
    imagedestroy($dst);
    echo "OK $out ({$size}px)\n";
}

// Vista previa grande en escala de grises (solo para revisar en PC)
$preview = renderIcon($src, 192);
imagepng($preview, $previewPath);
imagedestroy($preview);
echo "Preview: $previewPath (192px)\n";

imagedestroy($src);
echo "Listo.\n";
