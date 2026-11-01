#!/usr/bin/env php
<?php
# Baikal database upgrade, runnable without a web server.
#
# Runs Baikal's own upgrade code path (BaikalAdmin\Controller\Install\VersionUpgrade,
# the same one the web upgrade wizard uses) under php-cli, so it can be invoked
# from docker-entrypoint.d *before* the container's web server starts.
#
# Usage:
#   php baikal-cli-upgrade.php
#
# Required (environment variables):
#   BAIKAL_ROOT         Baikal installation root
#                       (must contain vendor/; e.g. /var/www/baikal)
#   BAIKAL_PATH_CONFIG  config directory override (understood by Baikal itself;
#                       defaults to $BAIKAL_ROOT/config/)
#   BAIKAL_PATH_SPECIFIC  Specific directory override (defaults to
#                       $BAIKAL_ROOT/Specific/)
#
# Exit codes:
#   0  upgrade completed, or nothing to do (fresh install / already up to date)
#   1  Baikal could not be bootstrapped, or the upgrade ran and Baikal reported a failure
#   2  misconfiguration (BAIKAL_ROOT does not point at a Baikal installation)
#
# NOTE: requires the PHP extensions Baikal's own bootstrap asserts
# (pdo + one of sqlite|mysql|pgsql, and the xml extension for XMLReader).

error_reporting(E_ALL);

define("BAIKAL_CONTEXT", true);
define("BAIKAL_CONTEXT_INSTALL", true);            # makes \Baikal::installTool() a no-op instead of a redirect
define("PROJECT_CONTEXT_BASEURI", "/admin/install/");

$sRoot = getenv('BAIKAL_ROOT');
if (!$sRoot || !is_dir($sRoot)) {
    fwrite(STDERR, "baikal-cli-upgrade: BAIKAL_ROOT must be set to the Baikal installation root\n");
    exit(2);
}
$sRoot = rtrim($sRoot, '/') . '/';
if (!is_file($sRoot . 'vendor/autoload.php')) {
    fwrite(STDERR, "baikal-cli-upgrade: BAIKAL_ROOT ($sRoot) does not look like a Baikal installation\n");
    exit(2);
}
define("PROJECT_PATH_ROOT", $sRoot);

# Baikal (Flake\Framework::bootstrap) reads these env vars to locate config/
# and Specific/. Only set the defaults; explicit env vars win.
if (!getenv('BAIKAL_PATH_CONFIG')) {
    putenv('BAIKAL_PATH_CONFIG=' . $sRoot . 'config/');
}
if (!getenv('BAIKAL_PATH_SPECIFIC')) {
    putenv('BAIKAL_PATH_SPECIFIC=' . $sRoot . 'Specific/');
}

# \Flake\Framework::bootstrap() reads $_SERVER to derive the project base URI.
# Provide a harmless stub; values are only used to build an unused internal URL.
$_SERVER += [
    "HTTP_HOST"       => "127.0.0.1",
    "SERVER_PORT"     => "80",
    "REQUEST_URI"     => "/admin/install/index.php",
    "SCRIPT_FILENAME" => $sRoot . "html/admin/install/index.php",
    "DOCUMENT_ROOT"   => $sRoot . "html/",
];

# Path of the config file, resolved here (pre-bootstrap) so we can bail out
# cleanly without running Baikal's bootstrap at all.
$sConfigDir  = rtrim(getenv('BAIKAL_PATH_CONFIG') ?: $sRoot . 'config', '/') . '/';
$sConfigFile = $sConfigDir . 'baikal.yaml';
if (!is_file($sConfigFile)) {
    echo "baikal-cli-upgrade: no config file ($sConfigFile); installation has not been done yet. Nothing to do in CLI mode; complete the install via the web wizard.\n";
    exit(0);
}

require PROJECT_PATH_ROOT . 'vendor/autoload.php';

try {
    \Flake\Framework::bootstrap();
    \BaikalAdmin\Framework::bootstrap();
} catch (\Throwable $e) {
    fwrite(STDERR, "baikal-cli-upgrade: could not bootstrap Baikal: " . $e->getMessage() . "\n");
    exit(1);
}

$config = \Symfony\Component\Yaml\Yaml::parseFile($sConfigFile);
$sConfigured = isset($config['system']['configured_version']) ? $config['system']['configured_version'] : null;

if ($sConfigured === null) {
    echo "baikal-cli-upgrade: config exists but is not initialized (no system.configured_version). Nothing to do in CLI mode.\n";
    exit(0);
}

echo "baikal-cli-upgrade: applying pending database upgrade $sConfigured -> " . BAIKAL_VERSION . "\n";

try {
    # render() performs the upgrade synchronously (VersionUpgrade::render()
    # calls upgrade() and updateConfiguredVersion()), exactly as the wizard's
    # GET request would.
    $oUpgrade = new \BaikalAdmin\Controller\Install\VersionUpgrade();
    $sOutput  = $oUpgrade->render();
} catch (\Throwable $e) {
    fwrite(STDERR, "baikal-cli-upgrade: UPGRADE FAILED (exception): " . $e->getMessage() . "\n");
    exit(1);
}

if (strpos($sOutput, 'has been successfully upgraded') !== false) {
    $config = \Symfony\Component\Yaml\Yaml::parseFile($sConfigFile);
    $sNew = isset($config['system']['configured_version']) ? $config['system']['configured_version'] : 'unknown';
    echo "baikal-cli-upgrade: upgrade completed; system.configured_version is now $sNew\n";
    exit(0);
}

if (strpos($sOutput, "There's no upgrade to be done") !== false) {
    echo "baikal-cli-upgrade: Baikal reports no upgrade to be done.\n";
    exit(0);
}

fwrite(STDERR, "baikal-cli-upgrade: UPGRADE FAILED; Baikal reported:\n" . $sOutput . "\n");
exit(1);
