@extends('layout.master')

@section('content')
<div class="text-black text-2xl m-10 font-extrabold">Edit Forum Details</div>
<div class="overflow-y-scroll bg-stone-500 m-10 rounded-lg">
    @if ($errors->any())
        <div class="alert alert-danger m-5">
            <ol>
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ol>
        </div>
    @endif

    <form class="bg-slate-100 p-5" method="POST" action="{{getenv('FORUM_CLIENT')}}/updateForum">
        @csrf

        <input type="hidden" name="id" id="id" value="{{$forum_content->id}}">
        <input type="hidden" name="slug" id="slug" value="{{$forum_content->slug}}">

        <div class="p-2">
            <label class="font-extrabold" for="body">Body</label>
            <div>
                <textarea name="body" id="body" rows="2" cols="40">{{$forum_content->body}}</textarea>
            </div>
        </div>

        <div class="p-2">
            <label class="font-extrabold" for="status">Status</label>
            <div>
                <select required name="status" id="status">
                    @foreach($statuses  as $key => $value)
                        <option
                            value="{{ $key }}" {{$forum_content->status == $key  ? 'selected' : ''}}>{{ $value}}</option>
                    @endforeach
                </select>
            </div>
        </div>

        <div class="p-5 text-right">
            <button class="btn" type="submit">Submit</button>
        </div>
    </form>
</div>
@endsection


@section('footer')
    <footer>© 2022 Client Forum</footer>
@endsection

