## 1. Tree contract scenarios
- [ ] 1.1 range_query computes same result as fold across leaves
- [ ] 1.2 insert preserves existing leaf values
- [ ] 1.3 remove preserves ordering of remaining leaves
- [ ] 1.4 canonical_nodes returns canonical covering

## 2. ScalarSummary contract scenarios
- [ ] 2.1 combine is associative and commutative
- [ ] 2.2 identity law: combine(identity, x) == x
- [ ] 2.3 derived_mean matches scalar computation

## 3. SamplePayload contract scenarios
- [ ] 3.1 combine uses elementwise sum statistics
- [ ] 3.2 regenerate increments revision
- [ ] 3.3 project_samples applies weight projection

## 4. SnapshotEpoch contract scenarios
- [ ] 4.1 insert produces new revision
- [ ] 4.2 concurrent writers are serialized
- [ ] 4.3 publish! atomically exchanges snapshot

## 5. DashboardModel contract scenarios
- [ ] 5.1 set_field! increments revision
- [ ] 5.2 subscribe! receives notifications
- [ ] 5.3 latest request wins
