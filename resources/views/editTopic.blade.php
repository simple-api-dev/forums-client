@extends('layout.master')

@section('content')
<div class="text-black text-2xl m-10 font-extrabold">Edit Topic Details</div>
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

<form class="bg-slate-100 p-5" action="{{getenv('FORUM_CLIENT')}}/updateTopic" method="POST">
    @csrf
    <input type="hidden" name="forum_id" id="forum_id" value="{{$forum_id}}">
    <input type="hidden" name="forum_slug" id="forum_slug" value="{{$forum_slug}}">
    <input type="hidden" name="id" id="id" value="{{$topic_content->id}}">

    <label class="font-extrabold">Title</label>
    <div>
        <span class="bg-slate-100">{{$topic_content->title}}</span>
    </div>

    <div class="p-2">
        <label class="font-extrabold" for="body">Body</label>
        <div>
        <textarea name="body" id="body" rows="3" cols="40">{{$topic_content->body}}</textarea>
        </div>
    </div>

    <label class="font-extrabold">Type</label>
    <div>
        <span class="bg-slate-100">{{$topic_content->type}}</span>
    </div>

    <div class="p-2">
        <label class="font-extrabold" for="status">Status</label>
        <div>
        <select required name="status" id="status">
            @foreach($statuses  as $key => $value)
                <option
                    value="{{ $key }}" {{$topic_content->status == $key  ? 'selected' : ''}}>{{ $value}}</option>
            @endforeach
        </select>
        </div>
    </div>

    <label class="font-extrabold">Author_id</label>
    <div>
        <span class="bg-slate-100">{{$topic_content->author_id}}</span>
    </div>

    @if(!empty($tags))
        <div class="p-2">
            <label class="font-extrabold" for="tags">Tags</label>
            <div>
                <select name="tags[]" id="tags" multiple>
                    @foreach($tags  as $key => $tag)
                        <option value="{{$tag->id}} {{Arr::exists($topic_content->tag_names, $tag->id)   ? 'selected=selected' : ''}}">{{$tag->name}}</option>
                    @endforeach
                </select>
            </div>
        </div>
    @endif


    <label class="font-extrabold">Reports</label>
    <div>
        <span class="bg-slate-100">reports</span>
    </div>

    <label class="font-extrabold">Score</label>
    <div>
        <span class="bg-slate-100">{{$topic_content->score}}</span>
    </div>

    <div class="p-5 text-right">
        <a class="bg-blue-800 rounded-lg p-1 text-white hover:bg-blue-600"
           href="{{getenv('FORUM_CLIENT')}}/forum/{{$forum_id}}/{{$forum_slug}}">Cancel</a>
        <button class="btn" type="submit">Submit</button>
    </div>
</form>
        @endsection


        @section('footer')
            <footer>© 2022 Client Forum</footer>
@endsection
