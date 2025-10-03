<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Usa POST con il parametro url.']);
    exit;
}

$url = $_POST['url'] ?? '';
if ($url === '' || !filter_var($url, FILTER_VALIDATE_URL)) {
    http_response_code(400);
    echo json_encode(['error' => 'Parametro url non valido.']);
    exit;
}

$storageDir = __DIR__ . '/pdf_storage';
if (!is_dir($storageDir) && !mkdir($storageDir, 0755, true) && !is_dir($storageDir)) {
    http_response_code(500);
    echo json_encode(['error' => 'Impossibile creare la cartella di destinazione.']);
    exit;
}

$path = parse_url($url, PHP_URL_PATH) ?? '';
$basename = trim(basename($path));
if ($basename === '' || stripos($basename, '.pdf') === false) {
    $basename = 'pdf_' . hash('crc32b', $url) . '.pdf';
}

// Sanitize filename to avoid directory traversal or weird characters.
$filename = preg_replace('/[^A-Za-z0-9._-]/', '_', $basename);
$targetPath = $storageDir . DIRECTORY_SEPARATOR . $filename;

if (file_exists($targetPath)) {
    echo json_encode(['status' => 'already_exists', 'file' => $filename]);
    exit;
}

$ch = curl_init($url);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_MAXREDIRS => 3,
    CURLOPT_TIMEOUT => 20,
    CURLOPT_USERAGENT => 'PharmaBox PDF downloader',
    CURLOPT_FAILONERROR => true,
]);

$pdfBinary = curl_exec($ch);
$curlErrNo = curl_errno($ch);
$curlErr   = curl_error($ch);
$info      = curl_getinfo($ch);
curl_close($ch);

if ($curlErrNo !== 0 || $pdfBinary === false) {
    http_response_code(502);
    echo json_encode(['error' => 'Download fallito', 'details' => $curlErr]);
    exit;
}

if (($info['http_code'] ?? 0) !== 200) {
    http_response_code(502);
    echo json_encode(['error' => 'Risposta HTTP non valida', 'status' => $info['http_code'] ?? null]);
    exit;
}

$contentType = $info['content_type'] ?? '';
if (stripos((string)$contentType, 'application/pdf') !== 0) {
    http_response_code(415);
    echo json_encode(['error' => 'Il file non è un PDF', 'contentType' => $contentType]);
    exit;
}

$maxBytes = 10 * 1024 * 1024; // 10 MB
if (strlen($pdfBinary) > $maxBytes) {
    http_response_code(413);
    echo json_encode(['error' => 'PDF troppo grande', 'limitBytes' => $maxBytes]);
    exit;
}

if (file_put_contents($targetPath, $pdfBinary) === false) {
    http_response_code(500);
    echo json_encode(['error' => 'Scrittura file fallita.']);
    exit;
}

echo json_encode([
    'status' => 'saved',
    'file' => $filename,
    'bytes' => strlen($pdfBinary),
    'path' => $targetPath,
]);
