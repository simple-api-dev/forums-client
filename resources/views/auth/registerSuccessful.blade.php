@extends('layout.master')
@section('content')
    <div class="text-black text-2xl m-10 font-extrabold">Register</div>
    <div class="overflow-y-scroll bg-stone-500 m-10 rounded-lg max-w-sm">
        <div>{{$message}}</div>
        @foreach($user as $key=>$value)
            {{$key}}: {{$value}}<br/>
        @endforeach
    </div>
@endsection
