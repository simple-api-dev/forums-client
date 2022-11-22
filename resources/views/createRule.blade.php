@extends('layout.master')

@section('content')
    <div class="text-black text-2xl m-10 font-extrabold">Create Forum Rule</div>
    <div class="overflow-y-scroll bg-stone-500 m-10 rounded-lg">

        <form class="bg-slate-200 p-5" action="{{getenv('FORUM_CLIENT')}}/storeRule" method="POST">
        @csrf

        <input type="hidden" name="forum_id" value="{{$forum_id}}">
        <input type="hidden" name="forum_slug" value="{{$forum_slug}}">

        <div class="p-2">
            <label class="font-extrabold" for="body">Body</label>
            <div>
                <textarea name="body" id="body" rows="2" cols="40"></textarea>
            </div>
        </div>

        <div class="p-2">
            <label class="font-extrabold" for="status">Status</label>
            <div>
                <select name="status" id="status">
                    <option value="Active">Active</option>
                    <option value="Draft" selected>Draft</option>
                    <option value="Disabled">Disabled</option>
                </select>
            </div>
        </div>

        <div class="p-2">
            <label class="font-extrabold" for="author_id">Author Id</label>
            <div>
                <input type="text" name="author_id" id="author_id">
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
