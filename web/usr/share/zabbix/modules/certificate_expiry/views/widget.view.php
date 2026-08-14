<?php

/**
 * Certificate Expiry widget view.
 *
 * @var CView $this
 * @var array $data
 */

$table = (new CTableInfo())
    ->setHeader([
        _('Certificate / IP'),
        _('Host'),
        _('Days left'),
        _('Expires on')
    ]);

$rows = array_slice($data['rows'], 0, 20);

foreach ($rows as $row) {

    $days = (float) $row['days_left'];

    if ($days < 7) {
        $days_class = 'certificate-expiry-critical';
    }
    elseif ($days < 15) {
        $days_class = 'certificate-expiry-high';
    }
    elseif ($days < 30) {
        $days_class = 'certificate-expiry-warning';
    }
    else {
        $days_class = 'certificate-expiry-ok';
    }

    $days_left = (new CSpan(number_format($days, 0).' d'))
        ->addClass('certificate-expiry-days')
        ->addClass($days_class);

    /*
     * Latest data:
     * - 해당 호스트
     * - component = cert
     */
    $latest_data_url = (new CUrl('zabbix.php'))
        ->setArgument('action', 'latest.view')
        ->setArgument('hostids[]', $row['hostid'])
        ->setArgument('name', '')
        ->setArgument('evaltype', 0)
        ->setArgument('tags[0][tag]', 'component')
        ->setArgument('tags[0][operator]', 1)
        ->setArgument('tags[0][value]', 'cert')
        ->setArgument('show_tags', 3);

    $certificate = (new CLink(
        $row['certificate'],
        $latest_data_url
    ))
        ->addClass('certificate-expiry-certificate');

    $host = (new CLink(
        $row['host'],
        $latest_data_url
    ))
        ->addClass('certificate-expiry-host');

    $expires_on = $row['expires_at'] !== null
        ? zbx_date2str(DATE_TIME_FORMAT, $row['expires_at'])
        : '-';

    $table->addRow([
        $certificate,
        $host,
        $days_left,
        $expires_on
    ]);
}

if (!$rows) {
    $table->setNoDataMessage(_('No certificate data found.'));
}

(new CWidgetView($data))
    ->addItem($table)
    ->show();