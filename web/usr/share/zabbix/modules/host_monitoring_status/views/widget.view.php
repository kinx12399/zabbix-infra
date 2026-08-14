<?php

/**
 * Host Monitoring Status widget view.
 *
 * @var CView $this
 * @var array $data
 */

$summary = $data['summary'];
$problem_hosts = $data['problem_hosts'];


/*
 * =========================================================
 * Summary
 * =========================================================
 */

$summary_box = (new CDiv())
    ->addClass('hms-summary');

$summary_items = [
    [
        'value' => $summary['total'],
        'label' => 'TOTAL',
        'class' => 'hms-total'
    ],
    [
        'value' => $summary['healthy'],
        'label' => 'HEALTHY',
        'class' => 'hms-healthy'
    ],
    [
        'value' => $summary['icmp'],
        'label' => 'ICMP',
        'class' => 'hms-icmp'
    ],
    [
        'value' => $summary['agent'],
        'label' => 'AGENT',
        'class' => 'hms-agent'
    ],
    [
        'value' => $summary['down'],
        'label' => 'DOWN',
        'class' => 'hms-down'
    ]
];

foreach ($summary_items as $summary_item) {

    $card = (new CDiv([
        (new CDiv($summary_item['value']))
            ->addClass('hms-value'),

        (new CDiv($summary_item['label']))
            ->addClass('hms-label')
    ]))
        ->addClass('hms-card')
        ->addClass($summary_item['class']);

    $summary_box->addItem($card);
}


/*
 * =========================================================
 * 정상 상태
 * =========================================================
 */

if (!$problem_hosts) {

    $problem_content = (new CDiv(
        (new CSpan(_('All monitored hosts are healthy.')))
            ->addClass('hms-all-healthy')
    ))
        ->addClass('hms-problem-empty');

    $content = (new CDiv([
        $summary_box,
        $problem_content
    ]))
        ->addClass('host-monitoring-status');
}


/*
 * =========================================================
 * 문제 호스트 존재
 * =========================================================
 */

else {

    $problem_header = (new CDiv([
        (new CSpan(_('Problem Hosts')))
            ->addClass('hms-problem-title'),

        (new CSpan(count($problem_hosts)))
            ->addClass('hms-problem-count')
    ]))
        ->addClass('hms-problem-header');


    $table = (new CTableInfo())
        ->addClass('hms-problem-table')
        ->setHeader([
            _('Host'),
            _('Status')
        ]);


    $rows = array_slice($problem_hosts, 0, 30);


    foreach ($rows as $row) {

        /*
         * Zabbix 기본 Host Context Menu
         *
         * 클릭 시:
         * - Dashboard
         * - Problems
         * - Latest data
         * - Graphs
         * - Web
         * - Inventory
         * - Host
         * - Items
         * - Triggers
         * - Discovery
         * - Scripts
         * 등이 표시됨.
         */
        $host = (new CLinkAction($row['host']))
            ->setMenuPopup(
                CMenuPopupHelper::getHost($row['hostid'])
            )
            ->addClass('hms-host');


        switch ((int) $row['status']) {

            case 1:
                $status_class = 'hms-status-icmp';
                break;

            case 2:
                $status_class = 'hms-status-agent';
                break;

            case 3:
                $status_class = 'hms-status-down';
                break;

            default:
                $status_class = '';
                break;
        }


        $status = (new CSpan($row['status_text']))
            ->addClass('hms-status');


        if ($status_class !== '') {
            $status->addClass($status_class);
        }


        $table->addRow([
            $host,
            $status
        ]);
    }


    $content = (new CDiv([
        $summary_box,
        $problem_header,
        $table
    ]))
        ->addClass('host-monitoring-status');
}


/*
 * =========================================================
 * Widget 출력
 * =========================================================
 */

(new CWidgetView($data))
    ->addItem($content)
    ->show();