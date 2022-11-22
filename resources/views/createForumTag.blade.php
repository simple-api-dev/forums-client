@extends('layout.master')

@section('content')
    <div class="text-black text-2xl m-10 font-extrabold">Create Forum Tag</div>
    <div class="overflow-y-scroll bg-stone-500 m-10 rounded-lg">
        <form class="bg-slate-200 p-5" action="{{getenv('FORUM_CLIENT')}}/storeForumTag" method="POST">
            @csrf

            <input type="hidden" name="forum_id" value="{{$forum_id}}">
            <input type="hidden" name="forum_slug" value="{{$forum_slug}}">

            <div class="p-2">
                <label class="font-extrabold" for="name">Name</label>
                <div>
                    <input type="text" name="name" id="name">
                </div>
            </div>

            <div class="p-5 text-right">
                <a class="bg-blue-800 rounded-lg p-1 text-white hover:bg-blue-600"
                   href="{{getenv('FORUM_CLIENT')}}/forum/{{$forum_id}}/{{$forum_slug}}">Cancel</a>
                <button class="btn" type="submit">Submit</button>
            </div>
        </form>
    </div>
@endsection


@section('footer')
    <footer>© 2022 Client Forum</footer>
@endsection




