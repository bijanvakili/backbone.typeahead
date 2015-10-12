should = require 'should'
global._ = require 'underscore'
global.Backbone = require 'backbone'
require '../src/backbone.typeahead.coffee'

describe 'Backbone Typeahead', ->
  describe 'Readme Tests', ->
    class Albums extends Backbone.TypeaheadCollection
        typeaheadAttributes: ['band', 'name', 'meta.members']

    beforeEach ->
      @albums = new Albums([
        { band: 'A Flock of Seagulls', name: 'A Flock of Seagulls', meta: { members: ['Mike Score'] }}
        { band: 'Rick Astley', name: 'Whenever You Need Somebody', meta: { members: ['Rick Astley'] }}
        { band: 'Queen', name: 'A Day at the Races', meta: { members: ['Freddie Mercury', 'Brian May'] }}
        { band: 'Queen', name: 'Tie Your Mother Down', meta: { members: ['Freddie Mercury', 'Brian May'] }}
      ])

    it 'should handle simple search', ->
      expected = ['Whenever You Need Somebody', 'Tie Your Mother Down']
      actual = _.map @albums.typeahead('you'), (a) -> a.get('name')

      actual.should.eql expected

    it 'should handle simple facet', ->
      expected = ['A Day at the Races']
      actual = _.map @albums.typeahead('ra', band: 'Queen'), (a) -> a.get('name')

      actual.should.eql expected

    it 'should handle simple nesting', ->
      expected = ['A Day at the Races', 'Tie Your Mother Down']
      actual = _.map @albums.typeahead('fred'), (a) -> a.get('name')

      actual.should.eql expected

  describe 'Support External Indexes for Facets', ->
    class IndexedCollection extends Backbone.TypeaheadCollection
      typeaheadAttributes: ['name']
      typeaheadIndexer: (facet, value) -> @index
      initialize: (models, options) -> @index = options.index

    it 'should respect the order of the list', ->
      collection = new IndexedCollection([
        { id: 1, name: 'Aa' }
        { id: 3, name: 'Ba' }
        { id: 2, name: 'Ab' }
      ], index: [2, 1])

      collection.typeaheadPreserveOrder = true

      expected = ['Aa', 'Ab']
      actual = _.map collection.typeahead('a', indexedFacet: 'this value does not matter'), (m) -> m.get('name')

      actual.should.eql expected

    it 'should allow for an external index', ->
      collection = new IndexedCollection([
        { id: 1, name: 'Aa' }
        { id: 2, name: 'Ab' }
        { id: 3, name: 'Ac' }
        { id: 4, name: 'Ad' }
        { id: 5, name: 'Ae' }
        { id: 6, name: 'Af' }
      ], index: [3, 5])

      expected = ['Ac', 'Ae']
      actual = _.map collection.typeahead('a', indexedFacet: 'this value does not matter'), (m) -> m.get('name')

      actual.should.eql expected

  describe 'Common Error States', ->
    it 'should handle a falsy id', ->
      class TestCollection extends Backbone.TypeaheadCollection
        typeaheadAttributes: ['name']

      collection = new TestCollection([
        { id: 3, name: 'Aa' }
        { id: 0, name: 'Ba' }
        { id: '', name: 'Bb' }
        { id: false, name: 'Ca' }
        { id: 7, name: 'Bc' }
      ])

      expected = ['Ba', 'Bb', 'Bc']
      actual = _.map collection.typeahead('b'), (m) -> m.get('name')

      actual.should.eql expected
      collection._adjacency['b'].length.should.eql 3

    it 'should handle an empty collection', ->
      class TestCollection extends Backbone.TypeaheadCollection
        typeaheadAttributes: ['id']

      collection = new TestCollection()

      expected = []
      actual = _.map collection.typeahead('a'), (m) -> m.id

      actual.should.eql expected

    it 'should handle empty search value', ->
      class TestCollection extends Backbone.TypeaheadCollection
        typeaheadAttributes: ['name', 'text']

      collection = new TestCollection([
        { id: 1, name: 'Aa' }
        { id: 2, name: 'Ab' }
        { id: 3, name: 'Ba' }
        { id: 4, name: 'Ac' }
      ])

      expected = ['Aa', 'Ab', 'Ba', 'Ac']
      actual = _.map collection.typeahead(' '), (m) -> m.get('name')

      actual.should.eql expected


    it 'should handle null/weird/missing attribute values', ->
      class BrokenCollection extends Backbone.TypeaheadCollection
        typeaheadAttributes: ['name', 'text']

      collection = new BrokenCollection([
        { name: null, text: 'Aa' }
        { name: 0, text: 'Ab' }
        { name: false, text: 'Ac' }
        { name: true, text: 'Ad' }
        { text: 'Ae'}
      ])

      expected = ['Aa', 'Ab', 'Ac', 'Ad', 'Ae']
      actual = _.map collection.typeahead('a'), (m) -> m.get('text')

      actual.should.eql expected

    it 'should handle similar numerics in tokens', ->
      class TestCollection extends Backbone.TypeaheadCollection
        typeaheadAttributes: ['name', 'text']

      collection = new TestCollection([
        { name: "01234567", text: 'Aa' }
        { name: "01234568", text: 'Ab' }
        { name: "01234569", text: 'Ac' }
      ])

      expected = ['Ac']
      actual = _.map collection.typeahead('01234569'), (m) -> m.get('text')

      actual.should.eql expected

    it 'should handle repeted character inputs', ->
      class TestCollection extends Backbone.TypeaheadCollection
        typeaheadAttributes: ['name', 'text']

      collection = new TestCollection([
        { name: "Apple Banana Aces", text: 'Aa' }
        { name: "Banana Apple Seal", text: 'Ab' }
        { name: "Carrot Car Carrier", text: 'Ac' }
      ])

      expected = []
      actual = _.map collection.typeahead('aaaaaaaaaaaa'), (m) -> m.get('text')

      actual.should.eql expected


  describe 'Common Backbone Scenarios', ->
    it 'should assume all attributes if missing the typeaheadAttributes member', ->
      collection = new Backbone.TypeaheadCollection([
        {id: 1, foo: 'Aa'}
        {id: 2, bar: 'Ab'}
      ])

      expected = [1, 2]
      actual = _.map collection.typeahead('a'), (m) -> m.id

      actual.should.eql expected

    it 'should handle attributes with array values', ->
      class MyModel extends Backbone.Model

      class MyCollection extends Backbone.TypeaheadCollection
        model: MyModel
        typeaheadAttributes: ['array']

      collection = new MyCollection([
        { id: 1, array: ['Aa', 'Ab'] }
        { id: 2, array: ['Aa'] }
        { id: 3, array: ['Bb'] }
      ])

      expected = [1, 2]
      actual = _.map collection.typeahead('a'), (m) -> m.id

      actual.should.eql expected

    it 'should support alternative ID attributes', ->
      json = '[{"url":"people/Nick-Kishfy","indexText":"Nick Kishfy Founder & CEO boss hiker ceo","title":"Nick Kishfy"}]'

      class PageModel extends Backbone.Model
        idAttribute: 'url'

      class PageCollection extends Backbone.TypeaheadCollection
        model: PageModel
        typeaheadAttributes: ['indexText']

      collection = new PageCollection(JSON.parse(json))

      collection.typeahead().length.should.eql collection.length
      collection._adjacency['n'].length.should.eql collection.length

    it 'should handle changing ID attribute value', ->
      json = '[{"url":"people/Nick-Kishfy","indexText":"Nick Kishfy Founder & CEO boss hiker ceo","title":"Nick Kishfy"}]'

      class PageModel extends Backbone.Model
        idAttribute: 'url'

      class PageCollection extends Backbone.TypeaheadCollection
        model: PageModel
        typeaheadAttributes: ['indexText']

      collection = new PageCollection(JSON.parse(json))

      collection.get('people/Nick-Kishfy').set('url', 'ceo')

      collection.typeahead().length.should.eql collection.length
      collection._adjacency['n'].length.should.eql collection.length

  describe 'Collection Changes', ->
    class Albums extends Backbone.TypeaheadCollection
      typeaheadAttributes: ['band', 'name']

    beforeEach ->
      @albums = new Albums([
        { band: 'A Flock of Seagulls', name: 'A Flock of Seagulls' }
        { band: 'Rick Astley', name: 'Whenever You Need Somebody' }
        { band: 'Queen', name: 'A Day at the Races' }
        { band: 'Queen', name: 'Tie Your Mother Down' }
      ])

    it 'should handle adding a model', ->
      @albums.add
        band: 'Band of Horses'
        name: 'Everything All The Time'

      expected = ['Tie Your Mother Down', 'Everything All The Time']
      actual = _.map @albums.typeahead('ti'), (m) -> m.get('name')

      actual.should.eql expected
      @albums._adjacency['t'].length.should.eql 3

    it 'should handle removing a model', ->
      @albums.remove @albums.where(band: 'Queen')

      expected = ['Whenever You Need Somebody']
      actual = _.map @albums.typeahead('you'), (a) -> a.get('name')

      actual.should.eql.expected
      @albums._adjacency['y'].length.should.eql 1

    it 'should handle changing a typeahead attribute value', ->
      model = @albums.findWhere(band: 'Rick Astley')
      model.set 'name', 'Hold Me in Your Arms'

      expected = ['Tie Your Mother Down', 'Hold Me in Your Arms']
      actual = _.map @albums.typeahead('m'), (m) -> m.get('name')

      actual.should.eql expected
      @albums._adjacency['m'].length.should.eql 2

  describe 'Nested Attributes', ->
    class Albums extends Backbone.TypeaheadCollection
        typeaheadAttributes: ['band', 'meta.name', 'meta.members']

    beforeEach ->
      @albums = new Albums([
        { band: 'A Flock of Seagulls', meta: { name: 'A Flock of Seagulls', members: ['Mike Score'] }}
        { band: 'Rick Astley', meta: { name: 'Whenever You Need Somebody', members: ['Rick Astley'] }}
        { band: 'Queen', meta: { name: 'A Day at the Races', members: ['Brian May'] }}
        { band: 'Queen', meta: { name: 'Tie Your Mother Down', members: ['Brian May'] }}
      ])

    it 'should handle string nested attributes', ->
      expected = ['A Day at the Races']
      actual = _.map @albums.typeahead('day'), (a) -> a.get('meta').name

      actual.should.eql expected

    it 'should handle array nested attributes', ->
      expected = ['A Day at the Races', 'Tie Your Mother Down']
      actual = _.map @albums.typeahead('Brian'), (a) -> a.get('meta').name

      actual.should.eql expected

  describe 'Custom tokenizer', ->
    class Albums extends Backbone.TypeaheadCollection
      typeaheadAttributes: ['band', 'meta.name', 'meta.members']
      tokenizeAttribute: (s) ->
        s = s.trim()
        return null if s.length is 0

        tokens = []

        for word in s.toLowerCase().split(/[\s\-_]+/)
          i = 0
          while i < word.length
            tokens.push(word.substr(i))
            i++

        tokens

    beforeEach ->
      @albums = new Albums([
        { band: 'A Flock of Seagulls', meta: { name: 'A Flock of Seagulls', members: ['Mike Score'] }}
        { band: 'Rick Astley', meta: { name: 'Whenever You Need Somebody', members: ['Rick Astley'] }}
        { band: 'Queen', meta: { name: 'A Day at the Races', members: ['Brian May'] }}
        { band: 'Queen', meta: { name: 'Tie Your Mother Down', members: ['Brian May'] }}
      ])

    it 'should handle string nested attributes', ->
      expected = ['A Day at the Races']
      actual = _.map @albums.typeahead('ces'), (a) -> a.get('meta').name

      actual.should.eql expected
