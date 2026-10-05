@php
    $playIcon = '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M7 4.5v15l12-7.5-12-7.5Z"/></svg>';
@endphp
@if ($legal['play_store_url'])
    <a class="btn btn-primary" href="{{ $legal['play_store_url'] }}" rel="noopener">{!! $playIcon !!} {{ $t['get_it'] }}</a>
@else
    <span class="btn btn-soon">{!! $playIcon !!} {{ $t['coming_soon'] }}</span>
@endif
