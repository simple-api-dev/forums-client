@extends('layout.master')

@section('content')
    <div class="text-black text-2xl m-10 font-extrabold">Create Topic</div>
    <div class="overflow-y-scroll bg-stone-500 m-10 rounded-lg">

        <form class="bg-slate-200 p-5" action="{{getenv('FORUM_CLIENT')}}/storeTopic" method="POST">
            @csrf

            <input type="hidden" name="forum_id" id="forum_id" value="{{$forum_id}}">
            <input type="hidden" name="forum_slug" id="forum_slug" value="{{$forum_slug}}">

            <div class="p-2">
                <label class="font-extrabold" for="title">Title</label>
                <div>
                    <input type="text" name="title" id="title">
                </div>
            </div>

            <div class="p-2">
                <label class="font-extrabold" for="body">Body</label>
                <div>
                    <textarea name="body" id="body" rows="3" cols="40" maxlength="512"></textarea>
                </div>
            </div>

            <div class="p-2">
                <label class="font-extrabold" for="type">Type</label>
                <div>
                    <select name="type" id="type">
                        <option value="Post">Post</option>
                        <option value="Video">Video</option>
                        <option value="Url">Url</option>
                        <option value="Image">Image</option>
                    </select>
                </div>
            </div>

            <div class="p-2">
                <label class="font-extrabold" for="status">Status</label>
                <div>
                    <select name="status" id="status">
                        <option value="Active">Active</option>
                        <option value="Draft">Draft</option>
                        <option value="Pending Review">Pending Review</option>
                        <option value="Locked">Locked</option>
                    </select>
                </div>
            </div>

            <div class="p-2">
                <label class="font-extrabold" for="author_id">Author Id</label>
                <div>
                    <input type="text" name="author_id" id="author_id">
                </div>
            </div>


            @if(!empty($tags))
                <div class="p-2">
                    <label class="font-extrabold" for="tags">Tags</label>
                    <div>
                        <select name="tags[]" id="tags" multiple>
                            @foreach($tags  as $key => $tag)
                                <option value="{{$tag->id}}">{{$tag->name}}</option>
                            @endforeach
                        </select>
                    </div>
                </div>
            @endif

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

