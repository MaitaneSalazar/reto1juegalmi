import { ComponentFixture, TestBed } from '@angular/core/testing';
import { CestaPage } from './cesta.page';

describe('CestaPage', () => {
  let component: CestaPage;
  let fixture: ComponentFixture<CestaPage>;

  beforeEach(() => {
    fixture = TestBed.createComponent(CestaPage);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
