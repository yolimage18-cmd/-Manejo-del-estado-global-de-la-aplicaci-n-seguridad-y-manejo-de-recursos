// Agrega a AndroidManifest.xml los permisos que necesita la app:
// UBICACIÓN (GPS) e INTERNET (para obtener el nombre del lugar), y sube la
// versión mínima de Android a 23 (la pide flutter_secure_storage).
//
// Uso (dentro de la carpeta fichaje_app, DESPUÉS de "flutter create ."):
//     node tool/configurar_android.js
//
// Es seguro ejecutarlo varias veces: si el permiso ya está, no lo duplica.

const fs = require('fs');
const path = require('path');

const manifestPath = path.join('android', 'app', 'src', 'main', 'AndroidManifest.xml');

if (!fs.existsSync(manifestPath)) {
  console.error('No encuentro ' + manifestPath);
  console.error('Primero ejecuta "flutter create ." dentro de la carpeta fichaje_app.');
  process.exit(1);
}

let xml = fs.readFileSync(manifestPath, 'utf8');

const permissions = [
  'android.permission.ACCESS_FINE_LOCATION',
  'android.permission.ACCESS_COARSE_LOCATION',
  'android.permission.INTERNET',
];

let added = 0;
for (const permission of permissions) {
  if (xml.includes('android:name="' + permission + '"')) {
    console.log('Ya estaba: ' + permission);
    continue;
  }
  // Se inserta justo después de la etiqueta de apertura <manifest ...>
  xml = xml.replace(/<manifest[^>]*>/, (tag) =>
    tag + '\n    <uses-permission android:name="' + permission + '"/>'
  );
  console.log('Agregado: ' + permission);
  added++;
}

if (added > 0) {
  fs.writeFileSync(manifestPath, xml, 'utf8');
  console.log('\nListo: AndroidManifest.xml actualizado.');
} else {
  console.log('\nNo hizo falta cambiar nada en AndroidManifest.xml.');
}

// ---- minSdk 23 (requisito de flutter_secure_storage) ----
const gradleCandidates = [
  path.join('android', 'app', 'build.gradle.kts'),
  path.join('android', 'app', 'build.gradle'),
];
const gradlePath = gradleCandidates.find((file) => fs.existsSync(file));

if (!gradlePath) {
  console.log('No encontré build.gradle: revisa que minSdk sea 23 o mayor.');
} else {
  let gradle = fs.readFileSync(gradlePath, 'utf8');
  const isKts = gradlePath.endsWith('.kts');
  const replacement = isKts ? 'minSdk = 23' : 'minSdkVersion 23';

  // Caso 1: usa el valor por defecto de Flutter (flutter.minSdkVersion).
  // Caso 2: tiene un número menor que 23.
  const usesFlutterDefault = /minSdk(Version)?\s*(=\s*)?flutter\.minSdkVersion/;
  const literal = /minSdk(Version)?\s*(=\s*)?(\d+)/;
  let changed = false;

  if (usesFlutterDefault.test(gradle)) {
    gradle = gradle.replace(usesFlutterDefault, replacement);
    changed = true;
  } else {
    const match = gradle.match(literal);
    if (match && parseInt(match[3], 10) < 23) {
      gradle = gradle.replace(literal, replacement);
      changed = true;
    }
  }

  if (changed) {
    fs.writeFileSync(gradlePath, gradle, 'utf8');
    console.log('Actualizado: minSdk = 23 en ' + gradlePath);
  } else {
    console.log('minSdk ya está bien en ' + gradlePath);
  }
}
