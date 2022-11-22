@extends('layout.master')

@section('content')
<div class="flex h-screen">
    <div class="flex-1 flex flex-col overflow-hidden">
        <header class="flex justify-between items-center bg-gray-300 p-4 rounded-lg">
            <div class="flex">
                <button class="bg-blue-800 rounded-lg p-3 text-white hover:bg-blue-600">
                    <a href="{{getenv('FORUM_CLIENT')}}">Forums</a>
                </button>
            </div>
            <div class="flex">
                Login
            </div>
        </header>

        <div class="flex max-h-[90%]">
            <main class="flex flex-col w-full bg-white overflow-y-auto overflow-x-auto m-10">
                <div>
                    <span class="text-black font-extrabold">{{$topic_content->body}}</span>
                </div>
                <div>
                    <form class="bg-slate-100 p-5" method="POST" action="{{getenv('FORUM_CLIENT')}}/storeCommentPost">
                        @csrf

                        <input type="hidden" id="forum_id" name="forum_id" value="{{$forum_id}}">
                        <input type="hidden" id="forum_slug" name="forum_slug" value="{{$forum_slug}}">
                        <input type="hidden" id="topic_id" name="topic_id" value="{{$topic_id}}">
                        <input type="hidden" id="topic_slug" name="topic_slug" value="{{$topic_slug}}">

                        <div class="p-2">
                            <div>
                                <textarea name="body" id="body" rows="2" cols="40" placeholder="What are your thoughts?">{{old('body')}}</textarea>
                            </div>
                        </div>

                        <div class="p-2">
                            <label class="font-extrabold" for="author_id">Author Id</label>
                            <div>
                                <input type="text" name="author_id" id="author_id" size="38"
                                       value="{{old('author_id')}}">
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
                                    <option value="Removed">Removed</option>
                                </select>
                            </div>
                        </div>

                        <div class="p-5 text-right">
                            <button class="btn" type="submit">
                                Submit
                            </button>
                        </div>
                    </form>
                </div>
                <div>
                    @foreach($topic_content->comments  as $key => $value)
                        <div class="m-5 p-5">
                            Comment:
                            <b>{{$value->commentable_type}}</b>
                            {{$value->body}}
                            {{$value->status}}
                            {{$value->author_id}}
                        </div>
                        <div>
                            <form class="bg-slate-100 p-5" method="POST" action="{{getenv('FORUM_CLIENT')}}/storeCommentCommentPost">
                                @csrf

                                <input type="hidden" id="forum_id" name="forum_id" value="{{$forum_id}}">
                                <input type="hidden" id="forum_slug" name="forum_slug" value="{{$forum_slug}}">
                                <input type="hidden" id="topic_id" name="topic_id" value="{{$topic_id}}">
                                <input type="hidden" id="topic_slug" name="topic_slug" value="{{$topic_slug}}">

                                <div class="p-2">
                                    <div>
                                        <textarea name="body" id="body" rows="2" cols="40" placeholder="What are your thoughts?">{{old('body')}}</textarea>
                                    </div>
                                </div>

                                <div class="p-2">
                                    <label class="font-extrabold" for="author_id">Author Id</label>
                                    <div>
                                        <input type="text" name="author_id" id="author_id" size="38"
                                               value="{{old('author_id')}}">
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
                                            <option value="Removed">Removed</option>
                                        </select>
                                    </div>
                                </div>

                                <div class="p-5 text-right">
                                    <button class="btn" type="submit">
                                        Submit
                                    </button>
                                </div>
                            </form>
                        </div>

                    @endforeach
                </div>
            </main>
        </div>
    </div>
</div>
@endsection


@section('footer')
    <footer>© 2022 Client Forum</footer>
@endsection
