<?php
/** Vista previa con fondo sólido (solo para revisar en Fotos / navegador). */
$src = __DIR__ . '/../../../../mesa_de_trabajo/obs_logo_antiguo/ic_stat_onesignal_preview_512.png';
$outDir = __DIR__ . '/../../../../mesa_de_trabajo/obs_logo_antiguo';

if (!file_exists($src)) {
    fwrite(STDERR, "Falta: $src\nEjecuta primero apply_gemini_notification_icon.php\n");
    exit(1);
}

$icon = imagecreatefrompng($src);
$w = imagesx($icon);
$h = imagesy($icon);

$backgrounds = [
    'preview_FONDO_OSCURO' => [0x1a, 0x1a, 0x1a],
    'preview_FONDO_TURQUESA' => [0x18, 0xE8, 0xBC],
    'preview_FONDO_GRIS' => [0x66, 0x66, 0x66],
];

foreach ($backgrounds as $name => $rgb) {
    $bg = imagecreatetruecolor($w, $h);
    $color = imagecolorallocate($bg, $rgb[0], $rgb[1], $rgb[2]);
    imagefill($bg, 0, 0, $color);
    imagealphablending($bg, true);
    imagesavealpha($bg, false);
    imagecopy($bg, $icon, 0, 0, 0, 0, $w, $h);
    $path = $outDir . '/ic_stat_onesignal_' . $name . '.png';
    imagepng($bg, $path);
    imagedestroy($bg);
    echo "OK $path\n";
}

// HTML con cuadriculado (abrir en Chrome/Edge)
$html = $outDir . '/ver_icono_notificacion.html';
$relIcon = 'ic_stat_onesignal_preview_512.png';
file_put_contents($html, <<<HTML
<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8"><title>Vista icono notificación</title>
<style>
body{font-family:sans-serif;background:#222;color:#fff;padding:24px}
.box{margin:16px 0;padding:16px;border-radius:8px}
.checker{background:repeating-conic-gradient(#888 0% 25%,#ccc 0% 50%) 50%/24px 24px}
.dark{background:#1a1a1a}
.teal{background:#18E8BC}
img{width:256px;height:256px;image-rendering:pixelated;border:1px solid #444}
h2{font-size:16px;margin:0 0 12px}
</style></head><body>
<h1>Icono pequeño notificación (Zigo Conductor)</h1>
<p>El PNG transparente se ve "todo blanco" en Fotos de Windows. Usa estas vistas:</p>
<div class="box checker"><h2>Cuadriculado (transparencia)</h2><img src="$relIcon" alt="icono"></div>
<div class="box dark"><h2>Fondo oscuro (como barra de notificaciones)</h2><img src="ic_stat_onesignal_preview_FONDO_OSCURO.png" alt=""></div>
<div class="box teal"><h2>Fondo turquesa Zigo</h2><img src="ic_stat_onesignal_preview_FONDO_TURQUESA.png" alt=""></div>
</body></html>
HTML);
echo "OK $html\n";
imagedestroy($icon);
