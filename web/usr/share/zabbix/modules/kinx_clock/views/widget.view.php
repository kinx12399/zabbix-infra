<?php

/**
 * KINX Clock widget view.
 *
 * @var CView $this
 * @var array $data
 */


/*
 * =========================================================
 * Header
 * =========================================================
 */

$header = (new CDiv([

    (new CSpan('KINX'))
        ->addClass('kinx-clock-header-brand'),

    (new CSpan('CDN INFRA MONITORING'))
        ->addClass('kinx-clock-header-title')

]))
    ->addClass('kinx-clock-header');


/*
 * =========================================================
 * Center brand
 * =========================================================
 */

$brand = (new CDiv(

    (new CSpan('KINX'))
        ->addClass('kinx-clock-brand')

))
    ->addClass('kinx-clock-brand-row');


/*
 * =========================================================
 * Date
 * =========================================================
 */

$date = (new CDiv(

    (new CSpan('---- -- --'))
        ->addClass('kinx-clock-date')

))
    ->addClass('kinx-clock-date-row');


/*
 * =========================================================
 * Time
 * =========================================================
 */

$time = (new CDiv([

    (new CSpan('--:--'))
        ->addClass('kinx-clock-time'),

    (new CSpan('--'))
        ->addClass('kinx-clock-seconds')

]))
    ->addClass('kinx-clock-time-row');


/*
 * =========================================================
 * Time zone
 * =========================================================
 */

$timezone = (new CDiv(

    (new CSpan('KST'))
        ->addClass('kinx-clock-zone')

))
    ->addClass('kinx-clock-zone-row');


/*
 * =========================================================
 * Footer
 * =========================================================
 */

$footer_left = (new CDiv([

    (new CSpan())
        ->addClass('kinx-clock-status-dot'),

    (new CSpan('ZABBIX 7.0 LTS'))
        ->addClass('kinx-clock-footer-text')

]))
    ->addClass('kinx-clock-footer-left');


$signal = (new CDiv([

    new CSpan(),
    new CSpan(),
    new CSpan(),
    new CSpan(),
    new CSpan(),
    new CSpan(),
    new CSpan(),
    new CSpan()

]))
    ->addClass('kinx-clock-signal');


$footer = (new CDiv([

    $footer_left,
    $signal

]))
    ->addClass('kinx-clock-footer');


/*
 * =========================================================
 * Main widget
 * =========================================================
 */

$content = (new CDiv([

    $header,
    $brand,
    $date,
    $time,
    $timezone,
    $footer

]))
    ->addClass('kinx-clock');


/*
 * =========================================================
 * Output
 * =========================================================
 */

(new CWidgetView($data))
    ->addItem($content)
    ->show();